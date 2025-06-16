import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../screens/finance/finance_category_screen.dart';
import '../../screens/finance/finance_transaction_form_screen.dart';
import '../../screens/finance/finance_report_screen.dart';
import '../../widgets/gradient_background.dart';
import '../../screens/bookings/bookings_screen.dart';
import '../profile_screen.dart';
import '../transactions/transactions_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FinanceTransactionRepository _transactionRepository =
      FinanceTransactionRepository();
  bool _isLoading = true;
  Map<String, int> _summary = {'income': 0, 'expense': 0, 'profit': 0};

  // Filter date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  int _selectedIndex = 1; // 0: Home, 1: Transaksi, 2: Booking, 3: Profile

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final summary = await _transactionRepository.getSummary(
        startDateStr,
        endDateStr,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat ringkasan keuangan');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSummary();
    }
  }

  void _onNavBarTap(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BookingsScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Back Button
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Keuangan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.date_range, color: Colors.white),
                      onPressed: _selectDateRange,
                      tooltip: 'Pilih Rentang Tanggal',
                    ),
                    IconButton(
                      icon: const Icon(Icons.category, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FinanceCategoryScreen(),
                          ),
                        );
                      },
                      tooltip: 'Kategori',
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.bar_chart, color: Colors.white),
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => FinanceReportScreen(
                    //           startDate: _startDate,
                    //           endDate: _endDate,
                    //         ),
                    //       ),
                    //     ).then((_) => _loadSummary());
                    //   },
                    //   tooltip: 'Laporan',
                    // ),
                  ],
                ),
              ),

              // Summary section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ringkasan Keuangan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${DateFormat('d MMM').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: (constraints.maxWidth - 24) / 3,
                                      child: _buildSummaryCard(
                                        'Pemasukan',
                                        currencyFormat.format(_summary['income'] ?? 0),
                                        Colors.green.shade400,
                                        Icons.arrow_downward,
                                      ),
                                    ),
                                    SizedBox(
                                      width: (constraints.maxWidth - 24) / 3,
                                      child: _buildSummaryCard(
                                        'Pengeluaran',
                                        currencyFormat.format(_summary['expense'] ?? 0),
                                        Colors.red.shade400,
                                        Icons.arrow_upward,
                                      ),
                                    ),
                                    SizedBox(
                                      width: (constraints.maxWidth - 24) / 3,
                                      child: _buildSummaryCard(
                                        'Laba Bersih',
                                        currencyFormat.format(_summary['profit'] ?? 0),
                                        Colors.blue.shade400,
                                        Icons.account_balance_wallet,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Custom Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, size: 18),
                          SizedBox(width: 8),
                          Text('Pemasukan'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, size: 18),
                          SizedBox(width: 8),
                          Text('Pengeluaran'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transactions list
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Income tab
                        FinanceTransactionListTab(
                          type: 'income',
                          startDate: _startDate,
                          endDate: _endDate,
                          onTransactionChanged: _loadSummary,
                        ),

                        // Expense tab
                        FinanceTransactionListTab(
                          type: 'expense',
                          startDate: _startDate,
                          endDate: _endDate,
                          onTransactionChanged: _loadSummary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FinanceTransactionFormScreen(
                type: _tabController.index == 0 ? 'income' : 'expense',
              ),
            ),
          ).then((_) => _loadSummary());
        },
        backgroundColor: _tabController.index == 0
            ? Colors.green.shade400
            : Colors.red.shade400,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Pemasukan' : 'Pengeluaran'),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceTransactionListTab extends StatefulWidget {
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onTransactionChanged;

  const FinanceTransactionListTab({
    Key? key,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.onTransactionChanged,
  }) : super(key: key);

  @override
  _FinanceTransactionListTabState createState() =>
      _FinanceTransactionListTabState();
}

class _FinanceTransactionListTabState extends State<FinanceTransactionListTab>
    with AutomaticKeepAliveClientMixin {
  final FinanceTransactionRepository _transactionRepository =
      FinanceTransactionRepository();
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(FinanceTransactionListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(widget.startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(widget.endDate);

      final transactions = await _transactionRepository.getTransactionsByType(
        widget.type,
      );

      // Filter by date range
      final filteredTransactions = transactions.where((tx) {
        final txDate = DateTime.parse(tx.date);
        return txDate.isAfter(
              widget.startDate.subtract(const Duration(days: 1)),
            ) &&
            txDate.isBefore(widget.endDate.add(const Duration(days: 1)));
      }).toList();

      setState(() {
        _transactions = filteredTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat transaksi');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await _transactionRepository.deleteTransaction(id);
      _loadTransactions();
      widget.onTransactionChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal menghapus transaksi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTransactions();
        widget.onTransactionChanged();
      },
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.type == 'income'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.type == 'income'
                            ? 'Belum ada data pemasukan'
                            : 'Belum ada data pengeluaran',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FinanceTransactionFormScreen(
                                type: widget.type,
                              ),
                            ),
                          ).then((_) {
                            _loadTransactions();
                            widget.onTransactionChanged();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          widget.type == 'income'
                              ? 'Tambah Pemasukan'
                              : 'Tambah Pengeluaran',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.type == 'income'
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    final transactionDate = DateTime.parse(transaction.date);
                    final formattedDate =
                        DateFormat('dd MMM yyyy').format(transactionDate);

                    return Dismissible(
                      key: Key(transaction.id.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Konfirmasi'),
                              content: const Text(
                                'Apakah Anda yakin ingin menghapus transaksi ini?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('BATAL'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('HAPUS'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _deleteTransaction(transaction.id);
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FinanceTransactionFormScreen(
                                  type: widget.type,
                                  transaction: transaction,
                                ),
                              ),
                            ).then((_) {
                              _loadTransactions();
                              widget.onTransactionChanged();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: widget.type == 'income'
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    widget.type == 'income'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: widget.type == 'income'
                                        ? Colors.green.shade400
                                        : Colors.red.shade400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        transaction.category,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  currencyFormat.format(transaction.amount),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.type == 'income'
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
