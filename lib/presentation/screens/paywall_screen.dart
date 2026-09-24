// 결제 화면 (이용권 안내)
// 작명 / 진단 / 묶음. 가격은 PurchaseService의 Prices 한 곳에서만.
// 받아 둔 결과가 있어야 결제할 수 있다 (결과 없이 결제되면 풀어줄 게 없어서 돈만 나감)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/purchase_service.dart';
import '../providers/naming_provider.dart';

class PaywallScreen extends StatefulWidget {
  final ProductType? highlightType;

  const PaywallScreen({super.key, this.highlightType});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late ProductType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.highlightType ?? ProductType.bundle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용권 선택'),
      ),
      body: Consumer<NamingProvider>(
        builder: (context, provider, _) {
          final products = provider.purchaseService.products
              .where((p) => p.type != ProductType.diagnosisUpgrade)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),

                const Text(
                  '케미연구소 이용권',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI 사주 분석으로 최적의 이름을 찾아보세요',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                ),

                const SizedBox(height: 28),

                // 상품 카드 3개
                ...products.map((product) => _buildProductCard(product)),

                const SizedBox(height: 24),

                // 구매 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: provider.purchaseBusy || !provider.canPurchase(_selectedType)
                        ? null
                        : () => provider.purchase(_selectedType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFC7C7CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: provider.purchaseBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            '${_getSelectedProduct(provider).priceString} 구매하기',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                // 지금 결제할 수 없는 이유
                if (!provider.canPurchase(_selectedType)) ...[
                  const SizedBox(height: 12),
                  Text(
                    _selectedType == ProductType.bundle
                        ? '묶음 할인은 결제 전인 작명 결과와 진단 결과가 하나씩 있을 때 쓸 수 있어요.'
                        : '먼저 ${_selectedType == ProductType.naming ? '작명' : '진단'}을 받아 보세요. 결과를 본 뒤에 결제할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.5),
                  ),
                ],

                const SizedBox(height: 20),

                // 안내 문구
                const Text(
                  '일회성 결제이며, 구독이 아닙니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  PlanProduct _getSelectedProduct(NamingProvider provider) {
    return provider.purchaseService.getProduct(_selectedType);
  }

  Widget _buildProductCard(PlanProduct product) {
    final isSelected = _selectedType == product.type;
    final isBundle = product.type == ProductType.bundle;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = product.type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFE5E5EA),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 라디오
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFC7C7CC),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // 제목 + 부제
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            product.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFF555555),
                            ),
                          ),
                          if (isBundle) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${Prices.format(context.read<NamingProvider>().purchaseService.bundleDiscount)} 할인',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF6B6B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ),

                // 가격
                Text(
                  product.priceString,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),

            // 포함 기능 (선택 시)
            if (isSelected) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0EDE8)),
              const SizedBox(height: 12),
              ...product.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
