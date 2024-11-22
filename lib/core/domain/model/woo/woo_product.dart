import 'package:enum_to_string/enum_to_string.dart';

import '../../../utils/enums/woo/woo_back_order_status.dart';
import '../../../utils/enums/woo/woo_catalog_visibility.dart';
import '../../../utils/enums/woo/woo_product_status.dart';
import '../../../utils/enums/woo/woo_product_type.dart';
import '../../../utils/enums/woo/woo_tax_status.dart';
import 'woo_product_attribute.dart';
import 'woo_product_category.dart';
import 'woo_product_dimensions.dart';
import 'woo_product_downloads.dart';
import 'woo_product_image.dart';
import 'woo_product_tag.dart';

class WooProduct {

  int id;
  String name;
  String slug;
  String permalink;
  DateTime? dateCreated;
  DateTime? dateCreatedGmt;
  DateTime? dateModified;
  DateTime? dateModifiedGmt;
  WooProductType type;
  WooProductStatus status;
  bool featured;
  WooCatalogVisibility catalogVisibility;
  String description;
  String shortDescription;
  String sku;
  double price;
  double regularPrice;
  double salePrice;
  DateTime? dateOnSaleFrom;
  DateTime? dateOnSaleFromGmt;
  DateTime? dateOnSaleTo;
  DateTime? dateOnSaleToGmt;
  bool onSale;
  bool purchasable;
  int totalSales;
  bool virtual;
  bool downloadable;
  List<WooProductDownload>? downloads;
  int downloadLimit;
  int downloadExpiry;
  String externalUrl;
  String buttonText;
  WooTaxStatus taxStatus;
  String taxClass;
  bool manageStock;
  int? stockQuantity;
  WooBackOrderStatus backorders;
  bool backordersAllowed;
  bool backordered;
  int? lowStockAmount;
  bool soldIndividually;
  String weight;
  WooProductDimensions? dimensions;
  bool shippingRequired;
  bool shippingTaxable;
  String shippingClass;
  int shippingClassId;
  bool reviewsAllowed;
  double averageRating;
  int ratingCount;
  List<String>? upsellIds;
  List<String>? crossSellIds;
  int parentId;
  String purchaseNote;
  List<WooProductCategory> categories;
  List<WooProductTag> tags;
  List<WooProductImage> images;
  Map<String, WooProductAttribute>? attributes;
  List<String>? variations;

  WooProduct({
    this.id = 0,
    this.name = '',
    this.slug = '',
    this.permalink = '',
    this.dateCreated,
    this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    this.type = WooProductType.simple,
    this.status = WooProductStatus.publish,
    this.featured = false,
    this.catalogVisibility = WooCatalogVisibility.visible,
    this.description = '',
    this.shortDescription = '',
    this.sku = '',
    this.price = 0.0,
    this.regularPrice = 0.0,
    this.salePrice = 0.0,
    this.dateOnSaleFrom,
    this.dateOnSaleFromGmt,
    this.dateOnSaleTo,
    this.dateOnSaleToGmt,
    this.onSale = false,
    this.purchasable = false,
    this.totalSales = 0,
    this.virtual = false,
    this.downloadable = false,
    this.downloads,
    this.downloadLimit = -1,
    this.downloadExpiry = -1,
    this.externalUrl = '',
    this.buttonText = '',
    this.taxStatus = WooTaxStatus.taxable,
    this.taxClass = '',
    this.manageStock = false,
    this.stockQuantity,
    this.backorders = WooBackOrderStatus.no,
    this.backordersAllowed = false,
    this.backordered = false,
    this.lowStockAmount,
    this.soldIndividually = false,
    this.weight = '',
    this.dimensions,
    this.shippingRequired = false,
    this.shippingTaxable = false,
    this.shippingClass = '',
    this.shippingClassId = 0,
    this.reviewsAllowed = true,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.upsellIds,
    this.crossSellIds,
    this.parentId = 0,
    this.purchaseNote = '',
    this.categories = const [],
    this.tags = const [],
    this.images = const [],
    this.attributes,
    this.variations
  });

  @override
  String toString() {
    return 'WooProduct{id: $id, name: $name, slug: $slug, permalink: $permalink, dateCreated: $dateCreated, dateCreatedGmt: $dateCreatedGmt, dateModified: $dateModified, dateModifiedGmt: $dateModifiedGmt, type: $type, status: $status, featured: $featured, catalogVisibility: $catalogVisibility, description: $description, shortDescription: $shortDescription, sku: $sku, price: $price, regularPrice: $regularPrice, salePrice: $salePrice, dateOnSaleFrom: $dateOnSaleFrom, dateOnSaleFromGmt: $dateOnSaleFromGmt, dateOnSaleTo: $dateOnSaleTo, dateOnSaleToGmt: $dateOnSaleToGmt, onSale: $onSale, purchasable: $purchasable, totalSales: $totalSales, virtual: $virtual, downloadable: $downloadable, downloads: $downloads, downloadLimit: $downloadLimit, downloadExpiry: $downloadExpiry, externalUrl: $externalUrl, buttonText: $buttonText, taxStatus: $taxStatus, taxClass: $taxClass, manageStock: $manageStock, stockQuantity: $stockQuantity, backorders: $backorders, backordersAllowed: $backordersAllowed, backordered: $backordered, lowStockAmount: $lowStockAmount, soldIndividually: $soldIndividually, weight: $weight, dimensions: $dimensions, shippingRequired: $shippingRequired, shippingTaxable: $shippingTaxable, shippingClass: $shippingClass, shippingClassId: $shippingClassId, reviewsAllowed: $reviewsAllowed, averageRating: $averageRating, ratingCount: $ratingCount, upsellIds: $upsellIds, crossSellIds: $crossSellIds, parentId: $parentId, purchaseNote: $purchaseNote, categories: $categories, tags: $tags, images: $images, attributes: $attributes}';
  }

  WooProduct.fromJSON(json) :
      id = json['id'],
      name = json['name'] ?? '',
      slug = json['slug'] ?? '',
      permalink = json['permalink'] ?? '',
      dateCreated = json['date_created'] != null ? DateTime.parse(json['date_created']) : null,
      dateCreatedGmt = json['date_created_gmt'] != null ? DateTime.parse(json['date_created_gmt']) : null,
      dateModified = json['date_modified'] != null ? DateTime.parse(json['date_modified']) : null,
      dateModifiedGmt = json['date_modified_gmt'] != null ? DateTime.parse(json['date_modified_gmt']) : null,
      type = EnumToString.fromString(WooProductType.values, json['type'] ?? WooProductType.simple.name) ?? WooProductType.simple,
      status = EnumToString.fromString(WooProductStatus.values, json['status'] ?? WooProductStatus.draft.name)!,
      featured = json['featured'] ?? false,
      catalogVisibility = EnumToString.fromString(WooCatalogVisibility.values, json['catalog_visibility'] ?? WooCatalogVisibility.visible.name) ?? WooCatalogVisibility.visible,
      description = json['description'].toString().replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true), '')
          .trim().split('\n')
          .where((line) => line.trim().isNotEmpty).join('\n\n'),
      shortDescription = json['short_description'].toString().replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true), '').trim(),
      sku = json['sku'] ?? '',
      price = double.tryParse(json['price'] ?? '0') ?? 0.0,
      regularPrice = double.tryParse(json['regular_price'] ?? '0') ?? 0.0,
      salePrice = double.tryParse(json['sale_price'] ?? '0') ?? 0.0,
      dateOnSaleFrom = json['date_on_sale_from'] != null ? DateTime.parse(json['date_on_sale_from']) : null,
      dateOnSaleFromGmt = json['date_on_sale_from_gmt'] != null ? DateTime.parse(json['date_on_sale_from_gmt']) : null,
      dateOnSaleTo = json['date_on_sale_to'] != null ? DateTime.parse(json['date_on_sale_to']) : null,
      dateOnSaleToGmt = json['date_on_sale_to_gmt'] != null ? DateTime.parse(json['date_on_sale_to_gmt']) : null,
      onSale = json['on_sale'] ?? false,
      purchasable = json['purchasable'] ?? false,
      totalSales = json['total_sales'] ?? 0,
      virtual = json['virtual'] ?? false,
      downloadable = json['downloadable'] ?? false,
      downloads = (json['downloads'] ?? []).map<WooProductDownload>((json) => WooProductDownload.fromJson(json)).toList(),
      downloadLimit = json['download_limit'] ?? -1,
      downloadExpiry = json['download_expiry'] ?? -1,
      externalUrl = json['external_url'] ?? '',
      buttonText = json['button_text'] ?? '',
      taxStatus = EnumToString.fromString(WooTaxStatus.values, json['tax_status'] ?? WooTaxStatus.taxable.name) ?? WooTaxStatus.taxable,
      taxClass = json['tax_class'] ?? '',
      manageStock = json['manage_stock'] ?? false,
      stockQuantity = json['stock_quantity'],
      backorders = EnumToString.fromString(WooBackOrderStatus.values, json['backorders'] ?? WooBackOrderStatus.no.name) ?? WooBackOrderStatus.no,
      backordersAllowed = json['backorders_allowed'] ?? false,
      backordered = json['backordered'] ?? false,
      lowStockAmount = json['low_stock_amount'],
      soldIndividually = json['sold_individually'] ?? false,
      weight = json['weight'] ?? '',
      dimensions = WooProductDimensions.fromJSON(json['dimensions']),
      shippingRequired = json['shipping_required'] ?? false,
      shippingTaxable = json['shipping_taxable'] ?? false,
      shippingClass = json['shipping_class'] ?? '',
      shippingClassId = json['shipping_class_id'] ?? 0,
      reviewsAllowed = json['reviews_allowed'] ?? true,
      averageRating = double.tryParse(json['average_rating'] ?? '0.0') ?? 0.0,
      ratingCount = json['rating_count'] ?? 0,
      upsellIds = List.from((json['upsell_ids'] ?? []).map((id) => id.toString())),
      crossSellIds = List.from((json['cross_sell_ids'] ?? []).map((id) => id.toString())),
      parentId = json['parent_id'] ?? 0,
      purchaseNote = json['purchase_note'] ?? '',
      categories = (json['categories'] ?? []).map<WooProductCategory>((json)=> WooProductCategory.fromJSON(json)).toList(),
      tags = (json['tags'] ?? []).map<WooProductTag>((json)=> WooProductTag.fromJSON(json)).toList(),
      images = (json['images'] ?? []).map<WooProductImage>((json)=> WooProductImage.fromJSON(json)).toList(),
      attributes = {for (var attribute in json['attributes'] ?? []) WooProductAttribute.fromJSON(attribute).name.toString(): WooProductAttribute.fromJSON(attribute)},
      variations = List.from((json['variations'] ?? []).map((id) => id.toString()));

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'permalink': permalink,
      'date_created': dateCreated?.toIso8601String(),
      'date_created_gmt': dateCreatedGmt?.toIso8601String(),
      'date_modified': dateModified?.toIso8601String(),
      'date_modified_gmt': dateModifiedGmt?.toIso8601String(),
      'type': EnumToString.convertToString(type),
      'status': EnumToString.convertToString(status),
      'featured': featured,
      'catalog_visibility': EnumToString.convertToString(catalogVisibility),
      'description': description,
      'short_description': shortDescription,
      'sku': sku,
      'price': price.toString(),
      'regular_price': regularPrice.toString(),
      'sale_price': salePrice.toString(),
      'date_on_sale_from': dateOnSaleFrom?.toIso8601String(),
      'date_on_sale_from_gmt': dateOnSaleFromGmt?.toIso8601String(),
      'date_on_sale_to': dateOnSaleTo?.toIso8601String(),
      'date_on_sale_to_gmt': dateOnSaleToGmt?.toIso8601String(),
      'on_sale': onSale,
      'purchasable': purchasable,
      'total_sales': totalSales,
      'virtual': virtual,
      'downloadable': downloadable,
      'downloads': downloads,
      'download_limit': downloadLimit,
      'download_expiry': downloadExpiry,
      'external_url': externalUrl,
      'button_text': buttonText,
      'tax_status': EnumToString.convertToString(taxStatus),
      'tax_class': taxClass,
      'manage_stock': manageStock,
      'stock_quantity': stockQuantity,
      'backorders': EnumToString.convertToString(backorders),
      'backorders_allowed': backordersAllowed,
      'backordered': backordered,
      'low_stock_amount': lowStockAmount,
      'sold_individually': soldIndividually,
      'weight': weight,
      'dimensions': dimensions?.toJSON(),
      'shipping_required': shippingRequired,
      'shipping_taxable': shippingTaxable,
      'shipping_class': shippingClass,
      'shipping_class_id': shippingClassId,
      'reviews_allowed': reviewsAllowed,
      'average_rating': averageRating.toString(),
      'rating_count': ratingCount,
      'upsell_ids': upsellIds,
      'cross_sell_ids': crossSellIds,
      'parent_id': parentId,
      'purchase_note': purchaseNote,
      'categories': categories.map((category) => category.toJSON()).toList(),
      'tags': tags.map((tag) => tag.toJSON()).toList(),
      'images': images.map((image) => image.toJSON()).toList(),
      'attributes': attributes?.values.map((attribute) => attribute.toJSON()).toList() ?? [],
      'variations': variations,
    };
  }

}
