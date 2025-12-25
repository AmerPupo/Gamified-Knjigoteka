import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:knjigoteka_desktop/providers/branch_provider.dart';
import 'package:knjigoteka_desktop/models/branch.dart';
import 'package:provider/provider.dart';

class BranchReportDialog extends StatefulWidget {
  final Branch branch;
  const BranchReportDialog({required this.branch});

  @override
  State<BranchReportDialog> createState() => _BranchReportDialogState();
}

class _BranchReportDialogState extends State<BranchReportDialog> {
  DateTime? _from;
  DateTime? _to;
  bool _loading = false;
  Map<DateTime, Map<String, int>> _results = {};
  int _totalSold = 0, _totalBorrowed = 0;
  String? _error;

  Future<void> _fetchReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<BranchProvider>(context, listen: false);
      final res = await provider.getReport(
        branchId: widget.branch.id,
        from: _from,
        to: _to,
      );
      setState(() {
        _totalSold = res['totalSold'] ?? 0;
        _totalBorrowed = res['totalBorrowed'] ?? 0;
        _results.clear();
        for (final entry in res['entries']) {
          final date = DateTime.parse(entry['date']);
          _results[date] = {
            'sold': entry['sold'] ?? 0,
            'borrowed': entry['borrowed'] ?? 0,
          };
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.7;
    final dialogHeight = size.height * 0.7;

    // Priprema podataka za chart
    final sortedEntries = _results.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final soldSpots = sortedEntries
        .asMap()
        .entries
        .map(
          (e) =>
              FlSpot(e.key.toDouble(), (e.value.value['sold'] ?? 0).toDouble()),
        )
        .toList();
    final borrowedSpots = sortedEntries
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            (e.value.value['borrowed'] ?? 0).toDouble(),
          ),
        )
        .toList();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.15,
        vertical: size.height * 0.15,
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Izvještaj za poslovnicu: ${widget.branch.name}",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Text("Od: "),
                ElevatedButton.icon(
                  icon: Icon(Icons.date_range),
                  label: Text(
                    _from == null
                        ? "Početak"
                        : DateFormat('dd.MM.yyyy').format(_from!),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _from ?? DateTime.now().subtract(Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _from = picked);
                  },
                ),
                SizedBox(width: 16),
                Text("Do: "),
                ElevatedButton.icon(
                  icon: Icon(Icons.date_range),
                  label: Text(
                    _to == null
                        ? "Kraj"
                        : DateFormat('dd.MM.yyyy').format(_to!),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _to ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _to = picked);
                  },
                ),
                SizedBox(width: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _fetchReport,
                  child: Text("Prikaži izvještaj"),
                ),
                SizedBox(width: 30),
                Text(
                  "Ukupno prodano: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("$_totalSold"),
                SizedBox(width: 20),
                Text(
                  "Ukupno iznajmljeno: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("$_totalBorrowed"),
              ],
            ),
            Divider(height: 36),
            if (_loading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    "Greška: $_error",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_results.isEmpty)
              Expanded(
                child: Center(child: Text("Nema podataka za izabrani period.")),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.show_chart, color: Colors.blueAccent, size: 22),
                    Text(
                      " Prodano",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                    SizedBox(width: 24),
                    Icon(Icons.show_chart, color: Colors.green, size: 22),
                    Text(" Iznajmljeno", style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: _getMaxY(soldSpots, borrowedSpots),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int idx = value.toInt();
                            if (idx < 0 || idx >= sortedEntries.length)
                              return SizedBox.shrink();
                            DateTime dt = sortedEntries[idx].key;
                            return Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                DateFormat('dd.MM').format(dt),
                                style: TextStyle(fontSize: 11),
                              ),
                            );
                          },
                          interval: 1,
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        color: Colors.blueAccent,
                        barWidth: 3,
                        spots: soldSpots,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        isCurved: false,
                        color: Colors.green,
                        barWidth: 3,
                        spots: borrowedSpots,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: sortedEntries
                      .map(
                        (e) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  DateFormat('dd.MM.yyyy').format(e.key),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: 36),
                              Text("Prodano: ${e.value['sold']}"),
                              SizedBox(width: 24),
                              Text("Iznajmljeno: ${e.value['borrowed']}"),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<FlSpot> a, List<FlSpot> b) {
    final values = [...a, ...b].map((e) => e.y).toList();
    double maxVal = values.isNotEmpty
        ? values.reduce((v, e) => v > e ? v : e)
        : 10;
    if (maxVal < 5) return 5;
    return (maxVal * 1.25).ceilToDouble();
  }
}
