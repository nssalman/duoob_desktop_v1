import 'package:duoob_desktop_app_v1/view/Report%20Screen/report_screen.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_workspace_listing.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. Navigation Rail (Far Left Menu)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Theme.of(context).primaryColor,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor:  Colors.white,
                child:  Icon(Icons.person, color:Theme.of(context).colorScheme.primary),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.task_alt_outlined,color: Colors.white,),
                selectedIcon: Icon(Icons.task_alt),
                label: Text('Tasks',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w400)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined,color: Colors.white,),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Reports',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w400)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined,color: Colors.white,),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w400)),
              ),
            ],
          ),
          
          // Divider between Rail and Content
          VerticalDivider(thickness: 1, width: 1, color: Theme.of(context).dividerColor),

          // 2. Main Content Area (Switches based on selection)
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                TaskWorkspace(),
                // PlaceholderPage(title: 'Reports & Analytics'),
                ReportWorkspace(),
                PlaceholderPage(title: 'Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Coming Soon'),
        ],
      ),
    );
  }
}
