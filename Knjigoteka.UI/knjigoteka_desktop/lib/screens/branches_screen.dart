import 'package:flutter/material.dart';
import 'package:knjigoteka_desktop/providers/city_provider.dart';
import 'package:knjigoteka_desktop/screens/branch_form_dialog.dart';
import 'package:knjigoteka_desktop/screens/branch_report_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../models/branch.dart';

class BranchesScreen extends StatefulWidget {
  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String _search = "";
  bool _loading = true;
  String? _error;
  List<Branch> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<BranchProvider>(context, listen: false);
      final results = await provider.searchBranches(fts: _search);
      setState(() => _branches = results);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value);
    _loadBranches();
  }

  void _editBranch(Branch branch) async {
    final cities = await Provider.of<CityProvider>(
      context,
      listen: false,
    ).getAll();

    showDialog(
      context: context,
      builder: (ctx) => BranchFormDialog(
        branch: branch,
        cities: cities,
        onSaved: (updated) async {
          await Provider.of<BranchProvider>(
            context,
            listen: false,
          ).update(updated.id, {
            "name": updated.name,
            "address": updated.address,
            "cityId": updated.cityId,
            "phoneNumber": updated.phoneNumber,
            "openingTime": updated.openingTime,
            "closingTime": updated.closingTime,
          });
          await _loadBranches();
        },
      ),
    );
  }

  void _deleteBranch(Branch branch) async {
    final provider = Provider.of<BranchProvider>(context, listen: false);
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text("Brisanje poslovnice")),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: Text(
          "Da li ste sigurni da želite obrisati poslovnicu '${branch.name}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Odustani"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Obriši"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await provider.delete(branch.id);
        _loadBranches();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Poslovnica obrisana.")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Greška pri brisanju: $e")));
      }
    }
  }

  void _addBranch() async {
    final cities = await Provider.of<CityProvider>(
      context,
      listen: false,
    ).getAll();
    showDialog(
      context: context,
      builder: (ctx) => BranchFormDialog(
        cities: cities,
        onSaved: (branch) async {
          await Provider.of<BranchProvider>(
            context,
            listen: false,
          ).insert(branch);
          _loadBranches();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive broj tile-ova po redu
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth ~/ 650).clamp(1, 3); // 2 ili 3 max

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poslovnice',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pretraži poslovnice po nazivu ili adresi...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addBranch,
                icon: Icon(Icons.add),
                label: Text("Dodaj novu"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF233348),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          if (_loading)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
            )
          else if (_branches.isEmpty)
            Expanded(child: Center(child: Text("Nema poslovnica.")))
          else
            Expanded(
              child: GridView.builder(
                itemCount: _branches.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 2.7,
                ),
                itemBuilder: (ctx, i) {
                  final b = _branches[i];
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black12,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Podaci centrirani vertikalno/horizontalno
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(b.address, style: TextStyle(fontSize: 16)),
                              Text(
                                "Grad: ${b.cityName}",
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                "Tel: ${b.phoneNumber}",
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                "Radno vrijeme: ${b.openingTime} - ${b.closingTime}",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        // Akcije centrirane
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              child: ElevatedButton(
                                onPressed: () => _editBranch(b),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF233348),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Uredi"),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 110,
                              child: ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) =>
                                        BranchReportDialog(branch: b),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Izvještaj"),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 110,
                              child: ElevatedButton(
                                onPressed: () => _deleteBranch(b),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Obriši"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
