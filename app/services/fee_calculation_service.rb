# Deterministic fee calculation: subtotal, discount, net, per-installment.
# Optional late-fee placeholder for future use.
class FeeCalculationService
  Result = Struct.new(:subtotal, :discount_amount, :discount_percent, :exempt, :net_amount, :installment_count, :per_installment, :late_fee, keyword_init: true)

  class << self
    # @param fee_assignment [FeeAssignment]
    # @param late_fee_amount [BigDecimal, nil] optional late fee (e.g. from config)
    # @return [FeeCalculationService::Result]
    def calculate(fee_assignment, late_fee_amount: nil)
      return Result.new(subtotal: 0, discount_amount: 0, discount_percent: 0, exempt: true, net_amount: 0, installment_count: 1, per_installment: 0, late_fee: 0) if fee_assignment.exempt?

      base = (fee_assignment.amount_override.presence || fee_assignment.fee.amount).to_d
      discount_pct = (fee_assignment.discount_percent.presence || 0).to_d
      discount_amt = (fee_assignment.discount_amount.presence || 0).to_d
      discount_total = discount_amt + (base * discount_pct / 100)
      net = [ base - discount_total, 0 ].max
      installments = (fee_assignment.installment_count.presence || 1).to_i
      installments = 1 if installments < 1
      per_installment = (net / installments).round(2)
      late_fee = (late_fee_amount || 0).to_d

      Result.new(
        subtotal: base,
        discount_amount: discount_amt,
        discount_percent: discount_pct,
        exempt: false,
        net_amount: net,
        installment_count: installments,
        per_installment: per_installment,
        late_fee: late_fee
      )
    end

    # Preview for a fee (no assignment): base amount and optional discount inputs.
    # @param fee [Fee]
    # @param discount_percent [Numeric, nil]
    # @param discount_amount [Numeric, nil]
    # @param installment_count [Integer, nil]
    # @return [FeeCalculationService::Result]
    def preview(fee, discount_percent: nil, discount_amount: nil, installment_count: nil)
      base = fee.amount.to_d
      pct = (discount_percent || 0).to_d
      amt = (discount_amount || 0).to_d
      discount_total = amt + (base * pct / 100)
      net = [ base - discount_total, 0 ].max
      installments = (installment_count || 1).to_i
      installments = 1 if installments < 1
      per_installment = (net / installments).round(2)

      Result.new(
        subtotal: base,
        discount_amount: amt,
        discount_percent: pct,
        exempt: false,
        net_amount: net,
        installment_count: installments,
        per_installment: per_installment,
        late_fee: 0
      )
    end
  end
end
