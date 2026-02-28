import 'package:flutter/material.dart';
import 'package:owvds/l10n/app_localizations.dart';

class DashboardContent extends StatelessWidget {
  final Color primaryColor;
  const DashboardContent({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboard,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 24),

        // Các thẻ thống kê
        _buildStatCards(l10n, context),

        const SizedBox(height: 32),

        // Biểu đồ & Hoạt động
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildProductionChart(l10n)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildRecentActivityList(l10n)),
                ],
              );
            }
            return Column(
              children: [
                _buildProductionChart(l10n),
                const SizedBox(height: 24),
                _buildRecentActivityList(l10n),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCards(AppLocalizations l10n, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: screenWidth > 800 ? 1.8 : 2.5,
      children: [
        _buildInfoCard(
          l10n.totalOrders,
          "1,240",
          Icons.shopping_bag_rounded,
          Colors.blue,
        ),
        _buildInfoCard(
          l10n.activePlans,
          "8",
          Icons.precision_manufacturing_rounded,
          Colors.orange,
        ),
        _buildInfoCard(
          l10n.revenue,
          "\$84K",
          Icons.attach_money_rounded,
          Colors.green,
        ),
        _buildInfoCard(
          l10n.lowStock,
          "12 Items",
          Icons.warning_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "12%",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductionChart(AppLocalizations l10n) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.productionOutput,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: _ModernChartPainter(color: primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(AppLocalizations l10n) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentActivities,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: 5,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Order #202${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    l10n.justNow,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.statusDone,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

// Custom Painter cho Biểu đồ (Có thêm Gradient mờ bên dưới Line)
class _ModernChartPainter extends CustomPainter {
  final Color color;
  _ModernChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.9,
      size.width * 0.4,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.45,
      size.width,
      size.height * 0.2,
    );

    // Vẽ vùng Gradient bên dưới Line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Vẽ Line chính
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
