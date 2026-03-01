import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
// Đường dẫn lùi 5 cấp để trỏ về core/widgets
import '../../../../../core/widgets/responsive_layout.dart';

class ProductionDashboard extends StatefulWidget {
  const ProductionDashboard({super.key});

  @override
  State<ProductionDashboard> createState() => _ProductionDashboardState();
}

class _ProductionDashboardState extends State<ProductionDashboard> {
  final Color _primaryColor = const Color(0xFF003366);

  // Bộ lọc cho biểu đồ
  String _selectedTimeframe = 'Tháng';
  final List<String> _timeframes = ['Ca', 'Ngày', 'Tuần', 'Tháng', 'Năm'];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề trang
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "QUẢN LÝ SẢN XUẤT",
              style: TextStyle(
                fontSize: isDesktop ? 26 : 22,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            // Nút thông báo
            IconButton(
              icon: Badge(
                label: const Text('3'),
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.notifications,
                  color: Colors.grey.shade600,
                  size: 28,
                ),
              ),
              tooltip: 'Thông báo',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bạn có 3 thông báo mới!')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- 1. KPI CARDS ---
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth < 600
                ? 2
                : (constraints.maxWidth < 1200 ? 2 : 4);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isDesktop ? 2.5 : 2.0,
              children: [
                _buildKPICard(
                  "Sản lượng Dệt nay",
                  "12,450 m",
                  Icons.waves,
                  Colors.blue,
                ),
                _buildKPICard(
                  "Sản lượng Nhuộm nay",
                  "8,320 kg",
                  Icons.format_color_fill,
                  Colors.purple,
                ),
                _buildKPICard(
                  "Máy đang chạy",
                  "45/50",
                  Icons.precision_manufacturing,
                  Colors.green,
                ),
                _buildKPICard(
                  "Phiếu chờ xử lý",
                  "12",
                  Icons.assignment_late,
                  Colors.orange,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // --- 2. BIỂU ĐỒ SẢN LƯỢNG (DỆT / NHUỘM) ---
        _buildChartSection(),
        const SizedBox(height: 32),

        // --- 3. KHU VỰC MENU TRUY CẬP NHANH ---
        _buildSectionTitle("DANH MỤC HỆ THỐNG", Icons.folder_special),
        _buildGridMenu([
          {
            'title': 'Bán thành phẩm',
            'icon': Icons.category,
            'color': Colors.indigo,
            'route': '/semi-finished',
          },
          {
            'title': 'Thành phẩm',
            'icon': Icons.check_circle,
            'color': Colors.deepPurple,
            'route': '#',
          },
          {
            'title': 'Máy móc',
            'icon': Icons.settings_input_component,
            'color': Colors.blueGrey,
            'route': '/machine-managements',
          },
          {
            'title': 'Rổ chứa',
            'icon': Icons.shopping_basket,
            'color': Colors.brown,
            'route': '/baskets',
          },
          {
            'title': 'Phụ tùng',
            'icon': Icons.build,
            'color': Colors.grey.shade700,
            'route': '#',
          },
        ]),
        const SizedBox(height: 24),

        _buildSectionTitle("VẬN HÀNH QUY TRÌNH", Icons.play_circle_fill),
        _buildGridMenu([
          // [MỚI] Thêm menu chức năng Điều độ Máy Dệt (Loom Assignment) vào trang chính
          {
            'title': 'Quản lý loom dệt',
            'icon': Icons.dashboard_customize,
            'color': Colors.blue.shade800,
            'route': '/loom-dashboard',
          },
          {
            'title': 'Quy trình Dệt',
            'icon': Icons.waves,
            'color': Colors.blue,
            'route': '/machine-operation',
          },
          {
            'title': 'Quy trình Nhuộm',
            'icon': Icons.format_color_fill,
            'color': Colors.purple,
            'route': '#',
          },
          {
            'title': 'Quy trình Cắt',
            'icon': Icons.content_cut,
            'color': Colors.redAccent,
            'route': '#',
          },
          {
            'title': 'Quy trình Cuộn',
            'icon': Icons.toll,
            'color': Colors.teal,
            'route': '#',
          },
          {
            'title': 'Đóng gói',
            'icon': Icons.inventory_2,
            'color': Colors.orange,
            'route': '#',
          },
        ]),
        const SizedBox(height: 24),

        _buildSectionTitle("QUẢN LÝ PHIẾU (TICKETS)", Icons.receipt_long),
        _buildGridMenu([
          {
            'title': 'Phiếu Rổ Dệt',
            'icon': Icons.receipt,
            'color': Colors.blue.shade700,
            'route': '#',
          },
          {
            'title': 'Phiếu Rổ Nhuộm',
            'icon': Icons.receipt,
            'color': Colors.purple.shade700,
            'route': '#',
          },
          {
            'title': 'Phiếu Cuộn',
            'icon': Icons.receipt,
            'color': Colors.teal.shade700,
            'route': '#',
          },
          {
            'title': 'Phiếu Cắt',
            'icon': Icons.receipt,
            'color': Colors.redAccent.shade700,
            'route': '#',
          },
          {
            'title': 'Phiếu In',
            'icon': Icons.print,
            'color': Colors.cyan.shade700,
            'route': '#',
          },
          {
            'title': 'Phiếu Đóng gói',
            'icon': Icons.local_shipping,
            'color': Colors.orange.shade700,
            'route': '#',
          },
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // WIDGETS BUILDERS
  // ===========================================================================

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildGridMenu(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2; // Mobile
        if (constraints.maxWidth >= 600 && constraints.maxWidth < 1000) {
          crossAxisCount = 4; // Tablet
        }
        if (constraints.maxWidth >= 1000) {
          crossAxisCount = 6; // Desktop
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () {
                if (item['route'] != '#') {
                  context.go(item['route']);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tính năng ${item['title']} đang phát triển!',
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 32, color: item['color']),
                    const SizedBox(height: 12),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- BIỂU ĐỒ ---
  Widget _buildChartSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // HEADER CHART: TABS + BỘ LỌC
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        _buildChartTabs(),
                        const SizedBox(height: 12),
                        _buildChartFilters(),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildChartTabs()),
                        _buildChartFilters(),
                      ],
                    ),
            ),

            // BODY CHART
            Container(
              height: 350,
              padding: const EdgeInsets.all(24),
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBarChart(Colors.blue), // Biểu đồ Dệt
                  _buildBarChart(Colors.purple), // Biểu đồ Nhuộm
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTabs() {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: _primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: _primaryColor,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(icon: Icon(Icons.waves, size: 18), text: "SẢN LƯỢNG DỆT"),
        Tab(
          icon: Icon(Icons.format_color_fill, size: 18),
          text: "SẢN LƯỢNG NHUỘM",
        ),
      ],
    );
  }

  Widget _buildChartFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút Xuất Excel
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đang xuất file Excel...')),
            );
          },
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text(
            'Xuất Excel',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 35),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dropdown Thời gian
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<String>(
            value: _selectedTimeframe,
            underline: const SizedBox(),
            icon: Icon(Icons.calendar_today, size: 16, color: _primaryColor),
            style: TextStyle(
              fontSize: 13,
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
            items: _timeframes
                .map((e) => DropdownMenuItem(value: e, child: Text("Theo $e")))
                .toList(),
            onChanged: (val) => setState(() => _selectedTimeframe = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Color barColor) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} Đơn vị\nTất cả sản phẩm',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                List<String> labels = [];
                if (_selectedTimeframe == 'Ca') {
                  labels = ['Ca A', 'Ca B', 'Ca C'];
                } else if (_selectedTimeframe == 'Ngày') {
                  labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                } else if (_selectedTimeframe == 'Tháng') {
                  labels = [
                    'Thg 1',
                    'Thg 2',
                    'Thg 3',
                    'Thg 4',
                    'Thg 5',
                    'Thg 6',
                  ];
                } else {
                  labels = ['Label 1', 'Label 2', 'Label 3', 'Label 4'];
                }

                if (value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[value.toInt()],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarGroup(0, 40, barColor),
          _makeBarGroup(1, 75, barColor),
          _makeBarGroup(2, 50, barColor),
          if (_selectedTimeframe != 'Ca') _makeBarGroup(3, 90, barColor),
          if (_selectedTimeframe != 'Ca') _makeBarGroup(4, 60, barColor),
          if (_selectedTimeframe == 'Ngày' || _selectedTimeframe == 'Tháng')
            _makeBarGroup(5, 85, barColor),
          if (_selectedTimeframe == 'Ngày') _makeBarGroup(6, 30, barColor),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}
