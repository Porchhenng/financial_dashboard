import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/custom_drawer.dart';
import '../widgets/dashboard_card.dart';

class FinancialDashboard extends StatefulWidget {
  @override
  _FinancialDashboardState createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard> {
  List<dynamic> projects = []; // Projects and branches data
  List<dynamic> branches = []; // Branches of the selected project
  Map<String, dynamic>? selectedBranch; // Currently selected branch data
  int? selectedProjectId; // Selected project ID
  String? selectedBranchName; // Selected branch name
  bool isLoading = true; // Loading state
  Map<String, double> sumData = {}; // Holds the sum data for display
  bool isSumMode = false;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/api/project'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          projects = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching projects: $e");
    }
  }

  void onProjectSelected(int? projectId) {
    setState(() {
      selectedProjectId = projectId;
      branches = projects
          .firstWhere((project) => project["id"] == projectId)["branches"];
      selectedBranch = null; // Reset selected branch
      selectedBranchName = null; // Reset branch dropdown
      sumData.clear(); // Clear sum data
      isSumMode = false; // Exit sum mode
    });
  }

  void onBranchSelected(String? branchName) {
    setState(() {
      selectedBranch =
          branches.firstWhere((branch) => branch["branch_name"] == branchName);
      selectedBranchName = branchName; // Update selected branch name
      sumData.clear(); // Clear sum data
      isSumMode = false; // Exit sum mode
    });
  }

  void calculateBranchSum() {
    if (branches.isEmpty) return;

    // Sum numeric fields across all branches
    final sum = <String, double>{};
    for (var branch in branches) {
      branch.forEach((key, value) {
        if (value is num) {
          sum[key] = (sum[key] ?? 0) + value.toDouble();
        }
      });
    }

    setState(() {
      sumData = sum;
      selectedBranch = null; // Clear selected branch
      selectedBranchName = null; // Clear branch dropdown
      isSumMode = true; // Enable sum mode
    });
  }

  void calculateProjectSum() {
    if (projects.isEmpty) return;

    // Sum numeric fields across all projects
    final sum = <String, double>{};
    for (var project in projects) {
      for (var branch in project["branches"]) {
        branch.forEach((key, value) {
          if (value is num) {
            sum[key] = (sum[key] ?? 0) + value.toDouble();
          }
        });
      }
    }

    setState(() {
      sumData = sum;
      selectedBranch = null; // Clear selected branch
      selectedBranchName = null; // Clear branch dropdown
      isSumMode = true; // Enable sum mode
    });
  }

  void resetView() {
    setState(() {
      sumData.clear(); // Clear sum data
      selectedBranch = null; // Reset selected branch
      selectedBranchName = null; // Reset branch dropdown
      isSumMode = false; // Exit sum mode
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine what to display
    final displayData = isSumMode
        ? sumData
        : selectedBranch != null
            ? selectedBranch
            : null;

    final filteredKeys = displayData?.keys
            .where((key) => !["branch_name", "id"].contains(key))
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(),
      appBar: AppBar(
        title: const Text(
          "Financial Report Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: calculateBranchSum,
                icon: const Icon(Icons.summarize, color: Colors.green),
                label: const Text(
                  "Sum All Branches",
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: calculateProjectSum,
                icon: const Icon(Icons.calculate, color: Colors.blue),
                label: const Text(
                  "Sum All Projects",
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: resetView,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                label: const Text(
                  "Reset",
                  style: TextStyle(color: Colors.grey),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Project Dropdown
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      fillColor:
                          Colors.white, // Ensures the background is white
                      filled: true, // Enables the fill color
                      labelText: "Select a Project",
                      labelStyle: TextStyle(
                          color:
                              Colors.black), // Optional: Make the label black
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            8), // Add rounded corners if needed
                        borderSide:
                            BorderSide(color: Colors.grey), // Border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    dropdownColor:
                        Colors.white, // Ensures the dropdown menu is white
                    value: selectedProjectId,
                    items: projects.map((project) {
                      return DropdownMenuItem<int>(
                        value: project["id"],
                        child: Text(
                          project["project_name"],
                          style: TextStyle(
                              color: Colors.black), // Optional: Text color
                        ),
                      );
                    }).toList(),
                    onChanged: onProjectSelected,
                  ),
                  SizedBox(height: 20),

                  // Branch Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      fillColor:
                          Colors.white, // Ensures the background is white
                      filled: true, // Activates the fill color
                      labelText: "Select a Branch",
                      labelStyle: TextStyle(
                          color: Colors.black), // Optional: Black label text
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Rounded corners
                        borderSide:
                            BorderSide(color: Colors.grey), // Border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey), // Border for enabled state
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.blue), // Border for focused state
                      ),
                    ),
                    dropdownColor: Colors
                        .white, // Ensures dropdown menu has a white background
                    value: selectedBranchName,
                    items: branches.map((branch) {
                      return DropdownMenuItem<String>(
                        value: branch["branch_name"],
                        child: Text(
                          branch["branch_name"],
                          style: TextStyle(
                              color:
                                  Colors.black), // Optional: Black text color
                        ),
                      );
                    }).toList(),
                    onChanged: onBranchSelected,
                  ),

                  SizedBox(height: 20),

                  // Cards Grid
                  displayData == null
                      ? const Center(
                          child: Text(
                            "Please select a project and a branch",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          physics:
                              NeverScrollableScrollPhysics(), // Disable GridView scrolling
                          shrinkWrap: true, // Wrap GridView inside ListView
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 3,
                          ),
                          itemCount: filteredKeys.length,
                          itemBuilder: (context, index) {
                            final key = filteredKeys[index];
                            final value = displayData[key];

                            // Assign dynamic colors and icons
                            Color cardColor;
                            IconData cardIcon;

                            if ([
                              "cogs",
                              "operational_expenses",
                              "accounts_payable",
                              "cashout"
                            ].contains(key)) {
                              cardColor = Colors.red;
                              cardIcon = Icons.remove_circle_outline;
                            } else if (key == "accounts_receivable") {
                              cardColor = Colors.green;
                              cardIcon = Icons.trending_up;
                            } else if (key == "petty_cash") {
                              cardColor = Colors.blue;
                              cardIcon = Icons.money_off;
                            } else if (key.contains("profit")) {
                              cardColor =
                                  value >= 0 ? Colors.green : Colors.red;
                              cardIcon = value >= 0
                                  ? Icons.monetization_on
                                  : Icons.money_off;
                            } else {
                              cardColor = Colors.green;
                              cardIcon = Icons.monetization_on;
                            }

                            return DashboardCard(
                              title: key.replaceAll("_", " ").toUpperCase(),
                              value: value.toString(),
                              color: cardColor,
                              icon: cardIcon,
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
