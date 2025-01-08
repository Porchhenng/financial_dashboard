import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManageProjectScreen extends StatefulWidget {
  @override
  _ManageProjectScreenState createState() => _ManageProjectScreenState();
}

class _ManageProjectScreenState extends State<ManageProjectScreen> {
  String? selectedProjectId; // Selected project ID
  String? selectedBranchId; // Selected branch ID
  List<dynamic> projects = []; // List of projects and their branches
  List<dynamic> branches = []; // List of branches in the selected project

  final Map<String, TextEditingController> _controllers = {
    'totalRevenue': TextEditingController(),
    'cogs': TextEditingController(),
    'operationalExpenses': TextEditingController(),
    'accountsPayable': TextEditingController(),
    'accountsReceivable': TextEditingController(),
    'pettyCash': TextEditingController(),
    'cashout': TextEditingController(),
  };

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();

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
        setState(() {
          projects = json.decode(response.body);
          // Reset selectedBranchId if the selected project has no branches
          if (selectedProjectId != null) {
            branches = projects.firstWhere((project) =>
                project["id"].toString() == selectedProjectId)["branches"];
            if (branches.isEmpty) {
              selectedBranchId = null;
            }
          }
        });
      } else {
        throw Exception('Failed to fetch projects');
      }
    } catch (e) {
      print("Error fetching projects: $e");
    }
  }

  void onProjectSelected(String? projectId) {
    setState(() {
      selectedProjectId = projectId;
      branches = projects.firstWhere(
          (project) => project["id"].toString() == projectId)["branches"];
    });
  }

  void onBranchSelected(String? branchId) {
    setState(() {
      selectedBranchId = branchId;
      print("Branch ID selected: $selectedBranchId"); // Add a debug print
    });
  }

  Future<void> createProject() async {
    if (_projectNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all project details")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/project'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "project_name": _projectNameController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project created successfully!")),
        );
        _projectNameController.clear();

        fetchProjects();
      } else {
        throw Exception('Failed to create project');
      }
    } catch (e) {
      print("Error creating project: $e");
    }
  }

  Future<void> createBranch() async {
    if (selectedProjectId == null || _branchNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select a project and enter branch name")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/branches'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "branch_name": _branchNameController.text,
          "project_id": int.parse(selectedProjectId!),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Branch created successfully!")),
        );
        _branchNameController.clear();
        // Refresh projects and branches
        fetchProjects();
      } else {
        throw Exception('Failed to create branch');
      }
    } catch (e) {
      print("Error creating branch: $e");
    }
  }

  Future<void> insertData() async {
    if (selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a branch")),
      );
      return;
    }

    print("Branch ID: $selectedBranchId"); // Debug print

    for (var entry in _controllers.entries) {
      if (entry.value.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${entry.key.replaceAll('_', ' ')} is empty")),
        );
        return;
      }
    }

    try {
      final requestData = {
        "branch_id": int.parse(selectedBranchId!),
        "total_revenue":
            double.tryParse(_controllers['totalRevenue']!.text) ?? 0.0,
        "cogs": double.tryParse(_controllers['cogs']!.text) ?? 0.0,
        "operational_expenses":
            double.tryParse(_controllers['operationalExpenses']!.text) ?? 0.0,
        "accounts_payable":
            double.tryParse(_controllers['accountsPayable']!.text) ?? 0.0,
        "accounts_receivable":
            double.tryParse(_controllers['accountsReceivable']!.text) ?? 0.0,
        "petty_cash": double.tryParse(_controllers['pettyCash']!.text) ?? 0.0,
        "cashout": double.tryParse(_controllers['cashout']!.text) ?? 0.0,
      };

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/branches/financial-data'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Financial data updated successfully!")),
        );
        _controllers.forEach((key, controller) => controller.clear());
      } else {
        throw Exception('Failed to update financial data: ${response.body}');
      }
    } catch (e) {
      print("Error inserting data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inserting data: $e")),
      );
    }
  }

  Future<void> deleteBranch(String branchId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/branch/$branchId'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Branch deleted successfully!")),
        );

        // Reset selectedBranchId and refresh the list
        setState(() {
          selectedBranchId = null; // Reset selected branch
        });
        fetchProjects(); // Refresh projects and branches
      } else {
        throw Exception('Failed to delete branch: ${response.body}');
      }
    } catch (e) {
      print("Error deleting branch: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting branch: $e")),
      );
    }
  }
  Future<void> deleteProject(String projectId) async {
  try {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/api/project/$projectId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Project deleted successfully!")),
      );

      // Refresh the project list after deletion
      setState(() {
        selectedProjectId = null; // Reset the selected project
      });
      fetchProjects(); // Refresh the project list
    } else {
      throw Exception('Failed to delete project: ${response.body}');
    }
  } catch (e) {
    print("Error deleting project: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error deleting project: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Sheet"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Create Project Section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Create Project",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(
                        labelText: "Project Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: createProject,
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              Colors.greenAccent)),
                      child: const Text(
                        "Create Project",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
  elevation: 3,
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Delete Project",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: "Select Project to delete",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.folder_open), // Project Icon
          ),
          value: selectedProjectId,
          items: projects.map((project) {
            return DropdownMenuItem<String>(
              value: project["id"].toString(),
              child: Text(project["project_name"]),
            );
          }).toList(),
          onChanged: (value) => setState(() {
            selectedProjectId = value;
          }),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () async {
            if (selectedProjectId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select a project to delete")),
              );
              return;
            }

            // Show confirmation dialog
            final confirmation = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Delete Project"),
                content: const Text(
                    "Are you sure you want to delete this project? This action cannot be undone."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Delete"),
                  ),
                ],
              ),
            );

            if (confirmation == true) {
              deleteProject(selectedProjectId!);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.delete, color: Colors.white),
          label: const Text("Delete Project", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  ),
),


            const SizedBox(height: 20),

            // Create Branch Section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Manage Branch",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Select Project Dropdown with Icon
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Project",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_open), // Project Icon
                      ),
                      value: selectedProjectId,
                      items: projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project["id"].toString(),
                          child: Text(project["project_name"]),
                        );
                      }).toList(),
                      onChanged: (value) => onProjectSelected(value),
                    ),
                    const SizedBox(height: 10),
                    // Select Branch Dropdown with Icon
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select A Branch to delete",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city), // Branch Icon
                      ),
                      value: selectedBranchId,
                      items: branches.map((branch) {
                        return DropdownMenuItem<String>(
                          value: branch["id"].toString(),
                          child: Text(branch["branch_name"]),
                        );
                      }).toList(),
                      onChanged: (value) => onBranchSelected(value),
                    ),
                    const SizedBox(height: 10),
                    // Enter Branch Name Text Field with Icon
                    TextField(
                      controller: _branchNameController,
                      decoration: const InputDecoration(
                        labelText: "Enter Branch Name to create",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit), // Edit Icon
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Buttons for Create and Delete with Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: createBranch,
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  Colors.greenAccent)),
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.white,
                          ), // Add Icon
                          label: const Text(
                            "Create Branch",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (selectedBranchId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please select a branch to delete")),
                              );
                              return;
                            }

                            final confirmation = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Branch"),
                                content: const Text(
                                    "Are you sure you want to delete this branch? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                            if (confirmation == true) {
                              deleteBranch(selectedBranchId!);
                            }
                          },
                          style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  Colors.redAccent)),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ), // Delete Icon
                          label: const Text(
                            "Delete Branch",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Insert Financial Data Section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add),
                        const Text("Insert Financial Data",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Project",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_open), // Project Icon
                      ),
                      value: selectedProjectId,
                      items: projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project["id"].toString(),
                          child: Text(project["project_name"]),
                        );
                      }).toList(),
                      onChanged: (value) => onProjectSelected(value),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Branch",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city), // Branch Icon
                      ),
                      value: selectedBranchId,
                      items: branches.map((branch) {
                        return DropdownMenuItem<String>(
                          value: branch["id"].toString(),
                          child: Text(branch["branch_name"]),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          onBranchSelected(value), // Call `onBranchSelected`
                    ),
                    SizedBox(height: 10),
                    ..._controllers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: entry.key.replaceAll('_', ' '),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: insertData,
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              Colors.greenAccent)),
                      child: const Text(
                        "Insert Financial Data",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
