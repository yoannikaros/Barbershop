import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/finance_transaction_repository.dart';
import 'package:fl_chart/fl_chart.dart';

class FinanceReportScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const FinanceReportScreen({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _FinanceReportScreenState createState() => _FinanceReportScreenState();
}

class _FinanceReportScreenState extends State<FinanceReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FinanceTransactionRepository _transactionRepository = FinanceTransactionRepository();
  bool _isLoading = true;
  Map<String, int> _summary = {'income': 0, 'expense': 0, 'profit': 0};
  List<Map<String, dynamic>> _incomeByCategory = [];
  List<Map<String, dynamic>> _expenseByCategory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(widget.startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(widget.endDate);
      
      // Get summary
      final summary = await _transactionRepository.getSummary(startDateStr, endDateStr);
      
      // Get income by category
      final incomeByCategory = await _transactionRepository.getCategorySummary('income', startDateStr, endDateStr);
      
      // Get expense by category
      final expenseByCategory = await _transactionRepository.getCategorySummary('expense', startDateStr, endDateStr);
      
      setState(() {
        _summary = summary;
        _incomeByCategory = incomeByCategory;
        _expenseByCategory = expenseByCategory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat data laporan');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ringkasan Keuangan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '${DateFormat('d MMM').format(widget.startDate)} - ${DateFormat('d MMM yyyy').format(widget.endDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Pemasukan',
                              currencyFormat.format(_summary['income'] ?? 0),
                              Colors.green,
                              Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              'Pengeluaran',
                              currencyFormat.format(_summary['expense'] ?? 0),
                              Colors.red,
                              Icons.arrow_upward,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              'Laba Bersih',
                              currencyFormat.format(_summary['profit'] ?? 0),
                              Colors.blue,
                              Icons.account_balance_wallet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chart and details
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Income tab
                      _buildCategoryReport(
                        _incomeByCategory,
                        'income',
                        Colors.green,
                        _summary['income'] ?? 0,
                        currencyFormat,
                      ),
                      
                      // Expense tab
                      _buildCategoryReport(
                        _expenseByCategory,
                        'expense',
                        Colors.red,
                        _summary['expense'] ?? 0,
                        currencyFormat,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryReport(
    List<Map<String, dynamic>> categoryData,
    String type,
    Color color,
    int total,
    NumberFormat currencyFormat,
  ) {
    if (categoryData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'income'
                  ? 'Belum ada data pemasukan'
                  : 'Belum ada data pengeluaran',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Prepare pie chart data
    final List<PieChartSectionData> pieChartSections = [];
    final List<Color> colors = [
      color,
      color.withOpacity(0.8),
      color.withOpacity(0.6),
      color.withOpacity(0.4),
      color.withOpacity(0.2),
    ];

    for (int i = 0; i < categoryData.length; i++) {
      final item = categoryData[i];
      final double percentage = (item['total'] / total) * 100;
      
      pieChartSections.add(
        PieChartSectionData(
          color: i < colors.length ? colors[i] : color.withOpacity(0.3),
          value: item['total'].toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie chart
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Category breakdown
          Text(
            type == 'income' ? 'Rincian Pemasukan' : 'Rincian Pengeluaran',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryData.length,
            itemBuilder: (context, index) {
              final item = categoryData[index];
              final double percentage = (item['total'] / total) * 100;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index < colors.length ? colors[index] : color.withOpacity(0.3),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      index < colors.length ? colors[index] : color.withOpacity(0.3),
                    ),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currencyFormat.format(item['total']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
