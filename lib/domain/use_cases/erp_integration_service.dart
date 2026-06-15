/// Agnostic, cross-module contract exposed by the ERP to the rest of the
/// ecosystem (shop, profile, bank, etc.).
///
/// Lives in `neom_core` so consumers like `neom_shop` can depend on the
/// contract WITHOUT depending on `neom_erp` (which holds private accounting
/// IP). The real implementation (`ErpIntegrationController`) is provided by
/// `neom_erp` and wired at runtime through the host app's `root_binding`.
///
/// All signatures use primitive types only — never ERP domain models
/// (`ErpBook`, `ErpIncome`, …) — to keep `neom_core` free of any ERP
/// dependency.
///
/// Apps that do NOT bundle the ERP simply leave this unregistered; callers
/// resolve it as `Sint.find<ErpIntegrationService?>()` and no-op when null.
abstract class ErpIntegrationService {

  /// Ingests a paid shop order into the ERP accounting layer.
  ///
  /// Re-reads the `shopOrders` document by [orderId] and, for each line item,
  /// records an `ErpSaleTransaction`, applies the revenue split, credits the
  /// author wallet and creates the EMXI income entry.
  ///
  /// MUST be idempotent: calling it twice for the same [orderId] must not
  /// duplicate transactions or double-credit wallets.
  ///
  /// Returns the number of sale transactions created (0 if the order was
  /// already ingested, not found, or not in a paid state).
  ///
  /// NOTE: The platform income is NOT recorded immediately. For each sale a
  /// pending finance change-approval request (neom_requests) is created so a
  /// finance role (UserRole.erp+) confirms the payment landed before the
  /// income is booked and the seller's royalty is released. See
  /// [finalizeSaleIncome].
  Future<int> ingestPaidOrder(String orderId);

  /// Finalizes a shop-sale income once a finance reviewer approves its
  /// change-approval request: records the EMXI income, credits the seller's
  /// royalty wallet and notifies the seller that their income is available.
  ///
  /// [data] is the approved request's payload (primitive map). Expected keys:
  ///   - `changes`     (Map)    — the ErpIncome JSON to insert
  ///   - `saleId`      (String) — sale txn to back-link with the income id
  ///   - `authorName`  (String) — seller/author display name
  ///   - `sellerEmail` (String) — seller email (wallet + notification target)
  ///   - `autorShare`  (double) — royalty amount to credit
  ///   - `bookTitle`, `buyerName`, `quantity` — for the notification text
  ///
  /// Returns true on success.
  Future<bool> finalizeSaleIncome(Map<String, dynamic> data);

  // ── Point of Sale (neom_pos) ───────────────────────────────────
  // Primitive-only contract so neom_pos never depends on neom_erp.

  /// Active sale points / branches (warehouse nodes) for the POS picker.
  /// Each map: `id`, `name`, `type`, `city`.
  Future<List<Map<String, dynamic>>> getPosNodes();

  /// Sellable catalog for a [nodeId] (stock resolved for that node).
  /// Each map: `bookId`, `barCode`, `name`, `author`, `price`, `stock`.
  Future<List<Map<String, dynamic>>> getPosCatalog(String nodeId);

  /// Records an in-person POS sale into the ERP accounting layer: creates the
  /// sale transaction(s), applies the revenue split, deducts node inventory,
  /// credits the author royalty wallet and books the platform income. Because
  /// the payment is collected on the spot, the income is booked immediately
  /// (no finance confirmation request, unlike online orders).
  ///
  /// [lineItems]: each map `bookId` (or `barCode`), `name`, `quantity`,
  /// `unitPrice`. Returns true if at least one line was recorded.
  Future<bool> recordPosSale({
    required String nodeId,
    required List<Map<String, dynamic>> lineItems,
    required String paymentMethod, // efectivo | tarjeta | tarjeta_mp | emxiCoin | mixto
    String buyerName,
    String buyerEmail,
    String cashierId,
    String sessionId,
    double discountPercent,
    String cardAuthCode, // card-terminal folio/authorization (e.g. MercadoPago)
  });

  /// Submits a POS refund / void for approval (sensitive: money out + restock).
  /// Creates a pending change-approval request reviewed inside the ERP by a
  /// higher role (developer+); the reversal is applied only on approval.
  /// [lineItems]: each `bookId` (or `barCode`), `name`, `quantity`, `unitPrice`.
  Future<bool> requestPosRefund({
    required String nodeId,
    required List<Map<String, dynamic>> lineItems,
    required double total,
    String receiptId,
    String cashierId,
    String reason,
  });

  /// Applies an approved POS refund: restocks the node inventory and books the
  /// returned money as a refund expense. [data] is the approved request payload.
  Future<bool> applyPosRefund(Map<String, dynamic> data);

  /// Accumulated, unpaid royalty balance for an author resolved by [authorEmail].
  /// Returns 0 when no wallet exists.
  Future<double> getAuthorWalletBalance(String authorEmail);

  /// Read-only royalty wallet summary for the author resolved by [authorEmail],
  /// for surfacing in the seller's dashboard (the author can SEE but not mutate
  /// their ERP wallet). Returns null when no wallet exists.
  ///
  /// Uses a primitive map (never ERP domain models) to keep `neom_core` free of
  /// any ERP dependency. Expected keys:
  ///   - `balance`      (double)  — unpaid accumulated royalties
  ///   - `totalEarned`  (double)  — lifetime earnings
  ///   - `totalPaid`    (double)  — lifetime payouts
  ///   - `currency`     (String)
  ///   - `lastSaleAt`   (int, epoch ms)
  ///   - `lastPayoutAt` (int, epoch ms)
  ///   - `payouts`      (List<Map>) most-recent-first, each with:
  ///       `amount` (double), `paymentMethod` (String), `reference` (String),
  ///       `timestamp` (int, epoch ms), `notes` (String)
  Future<Map<String, dynamic>?> getAuthorWalletSummary(String authorEmail);

  /// Records a royalty a creator earned from a channel OTHER than the shop
  /// (e.g. NUPALE reading royalties, CASETE listening royalties) into the
  /// author's ERP wallet, so the ERP wallet becomes the single consolidated
  /// ledger of creator earnings across EVERY channel (sale split + NUPALE +
  /// CASETE).
  ///
  /// Use this when the calling module has ALREADY deposited the amount to the
  /// creator's spendable balance — NUPALE/CASETE deposit AppCoins immediately
  /// each month. The amount is therefore added to the wallet's lifetime
  /// `totalEarned` AND `totalPaid` (the unpaid `balance` is left untouched,
  /// since the money was already paid out), and a payout entry is appended so
  /// it surfaces in the author's consolidated royalty history. The EMXI Coin
  /// wallet is NOT touched here (the caller already credited it), avoiding any
  /// double deposit.
  ///
  /// Creates the wallet on first external royalty for creators who never sold
  /// in the shop. [source] is a short channel tag ('nupale', 'casete', …).
  /// Returns true on success; no-ops to false when [authorEmail] is empty.
  Future<bool> recordExternalRoyalty(
    String authorEmail,
    double amount, {
    String authorName = '',
    String source = 'nupale',
    String reference = '',
    String concept = '',
  });

  /// Read-only CFDI (tax invoice) status for a shop [orderId], so the client
  /// (in their order detail) and finance can SEE whether the sale has been
  /// invoiced — WITHOUT depending on `neom_sat` or `neom_erp`.
  ///
  /// Resolves the chain order ↔ ErpSaleTransaction ↔ ErpIncome ↔ SatInvoice
  /// (the CFDI is keyed by the income id stored on the sale's `invoiceRef`).
  ///
  /// Returns null when the order was never ingested, has no income, or no
  /// invoice exists yet. Uses a primitive map (never SAT/ERP domain models).
  /// Expected keys:
  ///   - `status`      (String) raw status: 'draft' | 'timbrada' | 'cancelada' | 'error'
  ///   - `statusLabel` (String) human-readable label
  ///   - `uuid`        (String) fiscal UUID (empty until timbrado)
  ///   - `folio`       (String)
  ///   - `total`       (double)
  ///   - `incomeId`    (String) the ERP income / CFDI join key
  Future<Map<String, dynamic>?> getOrderInvoiceStatus(String orderId);

  /// Processes a royalty payout from an author's wallet, resolved by
  /// [authorEmail]. Debits the ERP wallet and the EMXI Coin wallet, and
  /// records the payout. Returns true on success.
  Future<bool> processRoyaltyPayout(
    String authorEmail,
    double amount, {
    String paymentMethod = 'transferencia',
    String reference = '',
    String notes = '',
  });

  /// Resolves an ecosystem account from an email or phone number so the POS can
  /// link an in-person sale to an existing user (user→client fusion). Returns
  /// `{id, name, email, phoneNumber, currentProfileId, subscriptionId}` or null
  /// when no match is found.
  Future<Map<String, dynamic>?> lookupAppUser(String query);
}
