/// Core domain models for Cunning Cat.
///
/// Identity follows ADR-0003: Product family -> Variant -> Listing.
/// The app compares *variants* (e.g. "Galaxy S25, 12GB/256GB, Navy");
/// a *listing* is one merchant/seller offering that variant.
library;

import 'package:flutter/widgets.dart';

class Category {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  /// Aspects reviewers score for this kind of product.
  final List<String> aspects;

  /// Extra words people type for this category ("fridge", "earbuds").
  final List<String> synonyms;

  const Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.aspects,
    this.synonyms = const [],
  });
}

class Merchant {
  final String id;
  final String name;
  final Color color;
  const Merchant({required this.id, required this.name, required this.color});
}

class Variant {
  final String id;
  final String familyName; // "Samsung Galaxy S25"
  final String brand;
  final Category category;
  final String variantLabel; // "12GB / 256GB · Navy"
  final Map<String, String> keySpecs;
  final int basePrice; // demo reference price used to generate listings
  final double rating; // 0-5
  final int reviewCount;
  const Variant({
    required this.id,
    required this.familyName,
    required this.brand,
    required this.category,
    required this.variantLabel,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    this.keySpecs = const {},
  });

  String get displayName => '$familyName ($variantLabel)';
}

class Listing {
  final String id;
  final String variantId;
  final String merchantId;
  final String sellerName;
  final bool authorisedSeller;
  final int price; // whole rupees, item price
  final int mrp;
  final int deliveryFee;
  final bool inStock;
  final DateTime observedAt;
  final String outboundUrl; // our /go/{click} redirect in production
  const Listing({
    required this.id,
    required this.variantId,
    required this.merchantId,
    required this.sellerName,
    required this.authorisedSeller,
    required this.price,
    required this.mrp,
    required this.deliveryFee,
    required this.inStock,
    required this.observedAt,
    required this.outboundUrl,
  });
}

enum OfferType { bankCard, upi, wallet, coupon, membership, exchange, firstOrder }

/// A payment method a user can own. We store the *type* only (bank + kind),
/// never card numbers, expiry dates or CVVs.
class PaymentInstrument {
  final String id; // e.g. 'hdfc_cc'
  final String bank; // 'HDFC Bank'
  final String kind; // 'Credit card', 'Debit card', 'UPI'
  const PaymentInstrument({required this.id, required this.bank, required this.kind});

  String get label => '$bank $kind';
}

class Offer {
  final String id;
  final String merchantId;
  final OfferType type;
  final String title;

  /// If non-empty, the user must own at least one of these instruments.
  final Set<String> requiredInstrumentIds;

  final double percent; // e.g. 10 for 10%
  final int flat; // flat rupees off
  final int? cap; // maximum discount in rupees
  final int minCart; // minimum item price for eligibility

  /// Instant discounts lower the payable amount; deferred cashback arrives later
  /// and is never mixed into the payable amount.
  final bool instant;

  /// Offers in the same stack group cannot be combined; the best one wins.
  final String stackGroup;

  final DateTime validUntil;

  /// Requires something we cannot confirm for this user
  /// (membership, first order, exchange of an old device).
  final bool needsExtraCondition;
  final String? conditionNote;

  /// When a human or feed last confirmed this offer.
  final DateTime verifiedAt;

  const Offer({
    required this.id,
    required this.merchantId,
    required this.type,
    required this.title,
    this.requiredInstrumentIds = const {},
    this.percent = 0,
    this.flat = 0,
    this.cap,
    this.minCart = 0,
    this.instant = true,
    required this.stackGroup,
    required this.validUntil,
    this.needsExtraCondition = false,
    this.conditionNote,
    required this.verifiedAt,
  });
}

enum Confidence { high, medium, low }

class ReportDimension {
  final String name;

  /// 0-10, or null when there is not enough evidence to score.
  final double? score;
  final Confidence? confidence;
  final String summary;
  final int evidenceCount;
  const ReportDimension({
    required this.name,
    required this.score,
    required this.confidence,
    required this.summary,
    required this.evidenceCount,
  });
}

class ReviewInsight {
  final String text;
  final bool positive;
  final String source; // e.g. "Retailer reviews (1,240)"
  const ReviewInsight({required this.text, required this.positive, required this.source});
}

class PricePoint {
  final DateTime date;
  final int lowestPrice;
  const PricePoint(this.date, this.lowestPrice);
}
