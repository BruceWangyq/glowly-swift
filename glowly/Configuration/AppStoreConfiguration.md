# App Store Configuration for Glowly Monetization

## In-App Purchase Setup Guide

### Prerequisites
1. Apple Developer Account with App Store Connect access
2. App ID configured with In-App Purchase capability
3. Tax and banking information completed in App Store Connect

### Product Configuration

#### Auto-Renewable Subscriptions

**Subscription Group: Glowly Premium**
- Group Name: `Glowly Premium`
- Group Reference Name: `GlowlyPremium`

##### Premium Monthly
- **Product ID**: `com.novuxlab.glowly.premium.monthly`
- **Reference Name**: `Premium Monthly`
- **Duration**: 1 Month
- **Price**: $4.99 USD
- **Free Trial**: 7 days
- **Family Sharing**: Enabled
- **Localized Information**:
  - **Display Name**: Premium Monthly
  - **Description**: Unlimited filters, retouch tools, HD export, exclusive content, and watermark removal. Perfect for regular users who want full access to all features.

##### Premium Yearly
- **Product ID**: `com.novuxlab.glowly.premium.yearly`
- **Reference Name**: `Premium Yearly`
- **Duration**: 1 Year
- **Price**: $29.99 USD (50% savings)
- **Free Trial**: 7 days
- **Family Sharing**: Enabled
- **Localized Information**:
  - **Display Name**: Premium Yearly
  - **Description**: All premium features with 50% savings compared to monthly. Best value for serious photo editors and content creators who use the app regularly.

#### Non-Consumable Products

##### Filter Packs

1. **Vintage Filters Pack**
   - Product ID: `com.novuxlab.glowly.pack.vintage_filters_pack`
   - Price: $0.99 USD
   - Description: Classic vintage-inspired filters with film grain effects and sepia tones for that perfect retro look.

2. **Cinematic Filters Pack**
   - Product ID: `com.novuxlab.glowly.pack.cinematic_filters_pack`
   - Price: $0.99 USD
   - Description: Movie-quality color grading and cinematic looks to give your photos professional film aesthetics.

3. **Portrait Filters Pack**
   - Product ID: `com.novuxlab.glowly.pack.portrait_filters_pack`
   - Price: $0.99 USD
   - Description: Perfect filters for portrait photography with skin smoothing and eye enhancement features.

4. **Fashion Filters Pack**
   - Product ID: `com.novuxlab.glowly.pack.fashion_filters_pack`
   - Price: $0.99 USD
   - Description: High-fashion editorial style filters with bold color palettes and professional styling effects.

##### Makeup Packs

1. **Glow Makeup Pack**
   - Product ID: `com.novuxlab.glowly.pack.glow_makeup_pack`
   - Price: $1.99 USD
   - Description: Natural glow effects and radiant skin enhancements for that perfect healthy complexion.

2. **Dramatic Makeup Pack**
   - Product ID: `com.novuxlab.glowly.pack.dramatic_makeup_pack`
   - Price: $2.99 USD
   - Description: Bold eye makeup and dramatic contouring effects for stunning evening looks and special occasions.

3. **Natural Makeup Pack**
   - Product ID: `com.novuxlab.glowly.pack.natural_makeup_pack`
   - Price: $1.99 USD
   - Description: Subtle everyday makeup enhancements with natural colors for a fresh-faced, effortless look.

4. **Festival Makeup Pack**
   - Product ID: `com.novuxlab.glowly.pack.festival_makeup_pack`
   - Price: $2.99 USD
   - Description: Creative festival looks with glitter effects and bold colors for party-ready styles and celebrations.

##### Collections

1. **Wedding Collection**
   - Product ID: `com.novuxlab.glowly.pack.wedding_collection`
   - Price: $2.99 USD
   - Description: Romantic filters with soft lighting and elegant effects perfect for weddings and special moments.

2. **Holiday Collection**
   - Product ID: `com.novuxlab.glowly.pack.holiday_collection`
   - Price: $2.99 USD
   - Description: Festive themed filters with holiday colors and seasonal effects for celebration photos.

3. **Summer Collection**
   - Product ID: `com.novuxlab.glowly.pack.summer_collection`
   - Price: $2.99 USD
   - Description: Bright summer vibes with sun-kissed effects and vibrant colors for beach-ready looks.

4. **Influencer Pack**
   - Product ID: `com.novuxlab.glowly.pack.influencer_pack`
   - Price: $4.99 USD
   - Description: Trending filters used by top influencers, social media optimized for viral looks and engagement.

##### Tool Packs

1. **Advanced Retouch Pack**
   - Product ID: `com.novuxlab.glowly.pack.advanced_retouch_pack`
   - Price: $3.99 USD
   - Description: Professional retouching tools with blemish removal and skin perfecting capabilities.

2. **Professional Tools Pack**
   - Product ID: `com.novuxlab.glowly.pack.professional_tools_pack`
   - Price: $3.99 USD
   - Description: Industry-standard professional tools with advanced controls and expert techniques.

### App Store Connect Configuration Steps

1. **Create Subscription Group**:
   - Go to Features > In-App Purchases
   - Click "+" and select "Auto-Renewable Subscriptions"
   - Create new subscription group: "Glowly Premium"

2. **Add Subscriptions**:
   - Add both monthly and yearly subscriptions to the group
   - Configure pricing for all supported territories
   - Add localized descriptions for major markets
   - Set up 7-day free trial for both subscriptions

3. **Create Non-Consumable Products**:
   - Add each filter pack, makeup pack, collection, and tool pack
   - Configure pricing tiers appropriate for each product
   - Add localized descriptions and screenshots

4. **Configure Family Sharing**:
   - Enable family sharing for subscription products
   - Consider enabling for premium content packs

5. **Set Up Promotional Offers**:
   - Introductory offers: 7-day free trial
   - Promotional offers for win-back campaigns
   - Offer codes for special events

### Pricing Strategy

#### Subscription Tiers
- **Monthly**: $4.99 (premium positioning)
- **Yearly**: $29.99 (50% discount, encourage annual commitment)
- **Free Trial**: 7 days (industry standard, allows full feature evaluation)

#### Microtransaction Pricing
- **Basic Filter Packs**: $0.99 (low barrier to entry)
- **Makeup Packs**: $1.99-$2.99 (higher value perception)
- **Collections**: $2.99-$4.99 (seasonal/special content premium)
- **Tool Packs**: $3.99 (professional tools command higher price)

### Localization

#### Supported Regions
- **Tier 1**: US, UK, Canada, Australia, Germany, France, Japan
- **Tier 2**: Spain, Italy, Netherlands, Sweden, South Korea
- **Tier 3**: Brazil, Mexico, India, China (with content adjustments)

#### Localized Pricing
- Use App Store Connect's automatic pricing tiers
- Adjust for local market conditions where necessary
- Consider regional purchasing power for premium features

### Compliance and Legal

#### App Store Guidelines
- Follow section 3.1 for in-app purchases
- Ensure proper restore functionality
- Implement family sharing correctly
- Use StoreKit for all transactions

#### Privacy and Data
- Update privacy policy for purchase data handling
- Implement proper receipt validation
- Secure customer payment information
- GDPR compliance for EU users

### Testing Configuration

#### StoreKit Configuration File
- Located at: `Configuration/StoreKitConfiguration.storekit`
- Includes all products with test data
- Enable for local testing and debugging

#### TestFlight Testing
- Test subscription flows with TestFlight users
- Verify family sharing functionality
- Test purchase restoration
- Validate receipt processing

### Launch Strategy

#### Soft Launch Markets
1. **Phase 1**: Canada, Australia (English-speaking, smaller markets)
2. **Phase 2**: UK, Germany (larger markets, different currencies)
3. **Phase 3**: US (primary market, full rollout)

#### Promotional Strategy
- Launch with 50% off first month promotion
- Influencer partnerships with promo codes
- App Store feature submission
- Social media campaign highlighting premium features

### Analytics and Optimization

#### Key Metrics to Track
- Free-to-paid conversion rate
- Trial-to-subscription conversion rate
- Monthly/yearly subscription mix
- Average revenue per user (ARPU)
- Customer lifetime value (LTV)
- Churn rate by cohort

#### A/B Testing Opportunities
- Paywall design and messaging
- Pricing tiers and positioning
- Free trial duration
- Feature gating strategies
- Upgrade prompt timing and frequency

### Post-Launch Optimization

#### Retention Strategies
- Win-back campaigns for lapsed subscribers
- Usage-based upgrade prompts
- Seasonal content and promotions
- Feature updates exclusive to premium users

#### Revenue Optimization
- Dynamic pricing based on user behavior
- Bundle offers for multiple content packs
- Limited-time exclusive collections
- Referral programs with subscription credits

### Support and Maintenance

#### Customer Support
- Subscription management help documentation
- Purchase restoration instructions
- Billing issue resolution process
- Feature request and feedback channels

#### Technical Maintenance
- Regular receipt validation monitoring
- Server-side receipt verification setup
- Fraud detection and prevention
- Performance monitoring for purchase flows

### Success Metrics

#### Target KPIs
- **Year 1**: 15% free-to-paid conversion rate
- **Month 6**: $2.50 average revenue per user
- **Month 12**: 70% annual subscription mix
- **Ongoing**: <5% monthly churn rate

#### Growth Targets
- 10K downloads in first month
- 1K paying subscribers by month 3
- $10K monthly recurring revenue by month 6
- 50K total downloads by year 1