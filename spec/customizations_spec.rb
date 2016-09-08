require 'spec_helper'

describe "customizations" do
  describe "Account" do
    def mock_account_request(account_number:, return_value:)
      relation = double
      expect(Z::Account).to receive(:where).with(account_number: account_number) { relation }
      expect(relation).to receive(:first).with(no_args) { return_value }
    end

    before do
      @account = Z::Account.new(id: "account_id", account_number: "A00000118", status: "Active")
    end

    describe "find_by_account_number!" do
      it "returns the zuora account if it exists" do
        mock_account_request(account_number: @account.account_number, return_value: @account)
        expect(Z::Account.find_by_account_number!(@account.account_number)).to eq(@account)
      end

      it "raises if the zuora account does not exist" do
        mock_account_request(account_number: @account.account_number, return_value: nil)
        expect {
          Z::Account.find_by_account_number!(@account.account_number)
        }.to raise_error(ActiveZuora::RecordNotFound, /Couldn't find Z::Account with account_number '#{@account.account_number}'/)
      end
    end

    describe "id_for_account_number" do
      it "returns the zuora account id if the zuora account exists and the id is present" do
        mock_account_request(account_number: @account.account_number, return_value: @account)
        expect(Z::Account.id_for_account_number(@account.account_number)).to eq(@account.id)
      end

      it "raises if the zuora account does not exist" do
        mock_account_request(account_number: @account.account_number, return_value: nil)
        expect {
          Z::Account.id_for_account_number(@account.account_number)
        }.to raise_error(ActiveZuora::RecordNotFound, /Couldn't find Z::Account with account_number '#{@account.account_number}'/)
      end

      it "raises if the zuora account exists but the id is not present" do
        @account.id = ""
        mock_account_request(account_number: @account.account_number, return_value: @account)
        expect {
          Z::Account.id_for_account_number(@account.account_number)
        }.to raise_error(ActiveZuora::ApiError, /id is not present for Z::Account with account_number '#{@account.account_number}'/)
      end
    end
  end

  describe "Invoice" do
    describe "invoice_body_for" do
      def mock_invoice_request(account_id:, invoice_number:, return_value:)
        relation, select_relation = double, double
        expect(Z::Invoice).to receive(:select).with(:body) { select_relation }
        expect(select_relation).to receive(:where).with(account_id: account_id, invoice_number: invoice_number) { relation }
        expect(relation).to receive(:first).with(no_args) { return_value }
      end

      before do
        @invoice = Z::Invoice.new(account_id: "some-id", invoice_number: "INV00000013", body: "pdf-body")
      end

      it "returns the invoice body if the invoice exists and the invoice body is present" do
        mock_invoice_request(account_id: @invoice.account_id, invoice_number: @invoice.invoice_number, return_value: @invoice)
        expect(Z::Invoice.invoice_body_for(account_id: @invoice.account_id, invoice_number: @invoice.invoice_number)).to eq(@invoice.body)
      end

      it "raises if the invoice does not exist" do
        mock_invoice_request(account_id: @invoice.account_id, invoice_number: @invoice.invoice_number, return_value: nil)
        expect {
          Z::Invoice.invoice_body_for(account_id: @invoice.account_id, invoice_number: @invoice.invoice_number)
        }.to raise_error(ActiveZuora::RecordNotFound, /Couldn't find Z::Invoice with invoice_number 'INV00000013' and account_id 'some-id'/)
      end

      it "raises if the invoice exists but the invoice body isn't present" do
        @invoice.body = ""
        mock_invoice_request(account_id: @invoice.account_id, invoice_number: @invoice.invoice_number, return_value: @invoice)
        expect {
          Z::Invoice.invoice_body_for(account_id: @invoice.account_id, invoice_number: @invoice.invoice_number)
        }.to raise_error(ActiveZuora::ApiError, /body is not present for Z::Invoice with invoice_number 'INV00000013' and account_id 'some-id'/)
      end
    end
  end
end





