import 'package:flutter/material.dart';

Future<String?> showSearchableOptionPicker({
  required BuildContext context,
  required String title,
  required List<String> options,
  String? initialValue,
}) async {
  final searchController = TextEditingController(text: initialValue ?? '');

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (builderContext, setState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredOptions = options.where((option) {
              final optionText = option.toLowerCase();
              return query.isEmpty || optionText.contains(query);
            }).toList();

            return SizedBox(
              height: MediaQuery.of(builderContext).size.height * 0.7,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(builderContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search here...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(builderContext).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredOptions.isEmpty
                        ? const Center(
                            child: Text('No matches found'),
                          )
                        : ListView.separated(
                            itemCount: filteredOptions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final option = filteredOptions[index];
                              final isSelected = initialValue == option;
                              return ListTile(
                                title: Text(option),
                                trailing: isSelected
                                    ? const Icon(Icons.check, color: Color(0xFF00C853))
                                    : null,
                                onTap: () => Navigator.pop(builderContext, option),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

const List<String> localJobOptions = [
  'Plumber (Domestic)',
  'Plumber (Emergency Repair)',
  'Borehole Technician',
  'Water Tank Cleaner',
  'Pump Installer',
  'Drain Cleaner',
  'Water Heater Technician',
  'Septic Tank Emptier',
  'Water Meter Installer',
  'Tap & Fixture Installer',
  'Leak Detection Specialist',
  'Water Filter Installer',
  'Electrician (Domestic)',
  'Generator Technician',
  'Solar Panel Installer',
  'Inverter Installer',
  'Air Conditioner Installer',
  'Air Conditioner Repairer',
  'Rewiring Electrician',
  'Prepaid Meter Installer',
  'Ceiling Fan Installer',
  'CCTV Camera Installer',
  'Satellite Dish / Canal+ Installer',
  'Mason (Bricklayer)',
  'Tiler (Floor & Wall)',
  'Painter (Wall & Building)',
  'POP Ceiling Designer',
  'Concrete Worker',
  'Foundation Builder',
  'Demolition Worker',
  'Waterproofing Specialist',
  'Roofer (Roof Repair)',
  'Scaffolder',
  'Paving Stone Layer',
  'Glazier (Window Glass)',
  'Welder (Gate Fabricator)',
  'Carpenter (Furniture)',
  'Carpenter (Roofing)',
  'Door Frame Installer',
  'Upholsterer (Sofa Repair)',
  'Locksmith (Key Specialist)',
  'Aluminum Fitter',
  'Cabinet Maker',
  'Wood Polisher',
  'Metal Gate Repairer',
  'Burglar Proof Installer',
  'Curtain Rail Installer',
  'Cleaner (Deep House)',
  'Cleaner (Post-Construction)',
  'Cleaner (Sofa & Carpet)',
  'Window Cleaner',
  'Laundry & Ironing Worker',
  'Office Cleaner',
  'Pest Control Specialist (Fumigation)',
  'Garbage Collector',
  'Compound Sweeper',
  'Tank Disinfector',
  'Septic Treatment Worker',
  'Gutter Cleaner',
  'Floor Polisher',
  'Grass Cutter (Lawn Mower)',
  'Tree Trimmer',
  'Landscape Gardener',
  'Flower Gardener',
  'Backyard Farm Installer',
  'Poultry Pen Builder',
  'Fish Pond Cleaner',
  'Soil Treater',
  'Weed Control Worker',
  'Stump Remover',
  'Yard Beautifier',
  'Fridge & Freezer Repairer',
  'Washing Machine Repairer',
  'Microwave & Oven Repairer',
  'Gas Cooker Repairer',
  'TV Repairer',
  'Sound System Installer',
  'Wi-Fi Router Technician',
  'Smart TV Installer',
  'Computer Repairer',
  'Battery Tester',
  'Intercom Installer',
  'Electric Fence Installer',
  'Automatic Gate Repairer',
  'Chef / Home Cook',
  'Event Decorator',
  'Tent / Canopy Rigger',
  'DJ / Sound Operator',
  'Event Usher',
  'Baker (Cakes & Snacks)',
  'Nanny / Babysitter',
  'Elderly Caregiver',
  'Tutor (Primary School)',
  'Tutor (Secondary School)',
  'Music Teacher',
  'Gym / Personal Trainer',
  'Hairbraider / Hairstylist',
  'Barber (Home Service)',
  'Makeup Artist',
  'Manicurist / Pedicurist',
];

const List<String> cameroonCityOptions = [
  'Centre - Yaoundé',
  'Centre - Mbalmayo',
  'Centre - Obala',
  'Centre - Bafia',
  'Centre - Eseka',
  'Centre - Akonolinga',
  'Littoral - Douala',
  'Littoral - Nkongsamba',
  'Littoral - Edéa',
  'Littoral - Mbanga',
  'Littoral - Yabassi',
  'Littoral - Loum',
  'South West - Buea',
  'South West - Limbe',
  'South West - Kumba',
  'South West - Tiko',
  'South West - Mamfe',
  'South West - Muyuka',
  'South West - Mundemba',
  'North West - Bamenda',
  'North West - Kumbo',
  'North West - Mbengwi',
  'North West - Wum',
  'North West - Ndop',
  'North West - Nkambe',
  'West - Bafoussam',
  'West - Dschang',
  'West - Foumban',
  'West - Mbouda',
  'West - Bangangté',
  'West - Bafang',
  'West - Baham',
  'South - Kribi',
  'South - Ebolowa',
  'South - Sangmélima',
  'South - Ambam',
  'South - Campo',
  'East - Bertoua',
  'East - Batouri',
  'East - Abong-Mbang',
  'East - Yokadouma',
  'East - Bélabo',
  'Adamaoua - Ngaoundéré',
  'Adamaoua - Meiganga',
  'Adamaoua - Tibati',
  'Adamaoua - Banyo',
  'North - Garoua',
  'North - Guider',
  'North - Figuil',
  'North - Lagdo',
  'Far North - Maroua',
  'Far North - Kousséri',
  'Far North - Mokolo',
  'Far North - Yagoua',
  'Far North - Mora',
];
