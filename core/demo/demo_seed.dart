/// Sample data for demo mode. Times are relative to "now" so the app always looks current.
Map<String, dynamic> seedDemoFarmer(String email) => {
      'id': 'demo-${email.hashCode.toUnsigned(32)}',
      'identifier': email,
      'name': email == demoAccountEmail ? 'Ali Khan' : null,
      'role': 'farmer',
      'farm_location': email == demoAccountEmail ? 'Chakwal, Punjab' : null,
      'language_preference': 'english',
      'timezone': 'Asia/Karachi',
      'is_active': true,
      'created_at': '2026-03-01T08:00:00',
    };

const demoAccountEmail = 'demo@peanutiq.app';

List<Map<String, dynamic>> seedAdvisories(String Function(Duration ago) at) => [
      {
        'id': 'adv-1',
        'title': 'Early Leaf Spot risk rising',
        'message':
            'Humid nights this week favour Early Leaf Spot in Chakwal and Talagang. Inspect lower leaves every two days and spray chlorothalonil (2 ml per litre) at the first brown spots with yellow halos.',
        'type': 'alert',
        'severity': 'high',
        'target_region': 'All',
        'created_at': at(const Duration(hours: 3)),
      },
      {
        'id': 'adv-2',
        'title': 'Irrigation tip',
        'message': 'Irrigate early in the morning to cut evaporation losses and keep leaves dry before nightfall.',
        'type': 'tip',
        'severity': 'low',
        'target_region': 'All',
        'created_at': at(const Duration(hours: 6)),
      },
      {
        'id': 'adv-3',
        'title': 'Heat wave expected on Friday',
        'message': 'Temperatures may reach 41°C. Avoid spraying at midday and check soil moisture at pegging depth.',
        'type': 'weather',
        'severity': 'medium',
        'target_region': 'All',
        'created_at': at(const Duration(days: 1)),
      },
      {
        'id': 'adv-4',
        'title': 'Collar rot reported near Attock',
        'message': 'Remove wilted plants with the soil around them and avoid over-irrigating low-lying fields.',
        'type': 'alert',
        'severity': 'medium',
        'target_region': 'Attock, Punjab',
        'created_at': at(const Duration(days: 3)),
      },
    ];

List<Map<String, dynamic>> seedActions(String Function(Duration ahead) due) => [
      {'id': 'act-1', 'title': 'Irrigate Field 2', 'category': 'Irrigation', 'due_date': due(const Duration(days: 1)), 'is_completed': false},
      {'id': 'act-2', 'title': 'Spray fungicide for leaf spot', 'category': 'Disease Control', 'due_date': due(const Duration(days: 3)), 'is_completed': false},
      {'id': 'act-3', 'title': 'Apply gypsum at pegging', 'category': 'Nutrition', 'due_date': due(const Duration(days: 5)), 'is_completed': true},
    ];

List<Map<String, dynamic>> seedActivities(String Function(Duration ago) at) => [
      {'id': 'log-1', 'action': 'Seed Quality Scan', 'details': 'Healthy', 'timestamp': at(const Duration(hours: 2))},
      {'id': 'log-2', 'action': 'Text Interactions', 'details': 'When should I irrigate?', 'timestamp': at(const Duration(hours: 7))},
      {'id': 'log-3', 'action': 'Disease Analysis', 'details': 'High Risk', 'timestamp': at(const Duration(days: 2))},
    ];

List<Map<String, dynamic>> seedScans(String Function(Duration ago) at) => [
      {
        'id': 'scan-1',
        'type': 'Disease Intelligence',
        'title': 'Late Leaf Spot Detection',
        'status': 'High Risk',
        'confidence_score': 98.1,
        'image_url': 'asset:///assets/images/demo_field.jpg',
        'created_at': at(const Duration(days: 2)),
      },
      {
        'id': 'scan-2',
        'type': 'Seed Intelligence',
        'title': 'Seed Quality Analysis',
        'status': 'Healthy',
        'confidence_score': 94.2,
        // A photo that no longer exists, to show the website's "Image Expired" state.
        'image_url': 'file:///demo/expired.jpg',
        'created_at': at(const Duration(days: 9)),
      },
    ];

List<Map<String, dynamic>> seedArticles(String Function(Duration ago) at) => [
      {
        'id': 'kb-1',
        'title': 'Managing Early and Late Leaf Spot',
        'category': 'Disease Management',
        'excerpt': 'How to recognise both leaf spot diseases and plan a fungicide schedule for humid weeks.',
        'content':
            'Early Leaf Spot shows brown spots with yellow halos on the upper leaf surface; Late Leaf Spot is darker and shows mainly on the underside. Scout lower leaves twice a week during humid spells and start a chlorothalonil programme at the first sign of disease, repeating every 10-14 days. Remove crop debris after harvest so the fungus cannot survive the winter.',
        'author': 'Dr. Sana Iqbal (NARC)',
        'is_published': true,
        'created_at': at(const Duration(days: 12)),
      },
      {
        'id': 'kb-2',
        'title': 'Sowing BARI-2016 in the Pothwar Region',
        'category': 'Cultivation Practices',
        'excerpt': 'Seed rate, sowing window and spacing for rain-fed peanut fields in Attock and Chakwal.',
        'content':
            'Sow between mid-April and May at 25-30 kg of shelled seed per acre with 45 cm between rows and 15 cm between plants. Treat seed with a fungicide before sowing and test germination on wet paper first: 85 of 100 seeds should sprout.',
        'author': 'BARI Extension Team',
        'is_published': true,
        'created_at': at(const Duration(days: 30)),
      },
      {
        'id': 'kb-3',
        'title': 'Seed Certification Standards',
        'category': 'Seed Quality Standards',
        'excerpt': 'What certified peanut seed must meet for purity, germination and moisture.',
        'content': 'Certified seed needs at least 98% physical purity, 70% germination and moisture below 9%. Buy only from registered dealers and keep the certification tag.',
        'author': 'FSC&RD',
        'is_published': true,
        'created_at': at(const Duration(days: 60)),
      },
      {
        'id': 'kb-4',
        'title': 'Peanut Yields in Chakwal, 2015-2025',
        'category': 'Historical Records',
        'excerpt': 'A decade of rain-fed yields and what the good years had in common.',
        'content': 'Average yields ranged from 11 to 16 maunds per acre. The best years combined timely April sowing, gypsum at pegging and at least two well-timed rains during pod fill.',
        'author': 'Agriculture Dept. Punjab',
        'is_published': true,
        'created_at': at(const Duration(days: 90)),
      },
      {
        'id': 'kb-5',
        'title': 'Reading the Leaf Spot Forecast',
        'category': 'Disease Forecasting',
        'excerpt': 'How humidity and night temperature drive the disease risk shown in the app.',
        'content': 'Risk rises when relative humidity stays above 85% for more than 10 hours and nights are between 20 and 28°C. Plan sprays two days ahead of forecast humid spells.',
        'author': 'Dr. Sana Iqbal (NARC)',
        'is_published': true,
        'created_at': at(const Duration(days: 5)),
      },
    ];

/// The website's sample seed result, in the backend's analysis format.
const demoSeedAnalysis = {
  'total_seeds': 342,
  'counts': {'healthy': 256, 'underdeveloped': 41, 'damaged': 28, 'diseased': 17},
  'percentages': {'healthy': 75, 'underdeveloped': 12, 'damaged': 8, 'diseased': 5},
  'grade': 'B',
  'germination_pct': 77,
  'size_uniformity_pct': 85,
  'color_consistency_pct': 92,
  'confidence_pct': 94,
  'summary': 'A good batch for planting after removing the damaged seeds.',
  'actions': [
    {'title': 'Proceed with planting', 'detail': 'Most seeds are healthy. Make sure the soil has enough moisture before sowing.'},
    {'title': 'Sort the batch', 'detail': 'Remove the broken and mouldy seeds (about 13%) to get an even stand.'},
  ],
};

/// The website's sample disease result, in the backend's analysis format.
const demoDiseaseAnalysis = {
  'category': 'disease',
  'condition_en': 'Early Leaf Spot',
  'condition': 'Early Leaf Spot',
  'confidence_pct': 94,
  'affected_pct': 35,
  'severity_stage': 2,
  'outbreak_risk': 'high',
  'explanation':
      'Brown to reddish-brown spots with yellow halos on the upper leaf surface, typical of Early Leaf Spot (Cercospora arachidicola).',
  'urgent_action': 'Spray a fungicide this week, before humid weather spreads it further.',
  'treatments': [
    {'title': 'Chemical control', 'detail': 'Spray chlorothalonil (2 ml per litre). Follow the product label and check with your local agriculture office.'},
    {'title': 'Cultural practices', 'detail': 'Improve drainage and avoid watering the leaves late in the day.'},
    {'title': 'Follow-up', 'detail': 'Check the crop again in 7-10 days and scan new photos to track recovery.'},
  ],
  'prevention': 'Rotate peanuts with cereals and remove infected plant debris after harvest.',
};
