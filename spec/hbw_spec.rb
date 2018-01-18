require 'spec_helper'
require 'hbw'

describe HBW do
  describe ".notify" do
    let(:default_args) { { raise_development: true, notice_only: false } }

    context "when only exception is passed as argument" do
      let(:ex) { RuntimeError.new("test error") }

      it "calls notify_raw with exception, raise_development, notice_only" do
        expect(HBW).to receive(:notify_raw).with(ex, default_args)
        HBW.notify(ex)
      end
    end

    context "when exception and options is passed" do
      let(:ex) { RuntimeError.new("test error") }

      it "calls notify_raw with options and exception, raise_development, notice_only" do
        expect(HBW).to receive(:notify_raw).with(ex, default_args.merge({ error_message: "RuntimeError", context: { user_id: 3 }, raise_development: false }))
        HBW.notify(ex, error_message: "RuntimeError", context: { user_id: 3 }, raise_development: false)
      end
    end

    context "when exception and Hash-options is passed" do
      let(:ex) { RuntimeError.new("test error") }

      it "calls notify_raw with options and exception, raise_development, notice_only" do
        expect(HBW).to receive(:notify_raw).with(ex, default_args.merge({ error_message: "RuntimeError", context: { user_id: 3 }, raise_development: false }))
        HBW.notify(ex, { error_message: "RuntimeError", context: { user_id: 3 }, raise_development: false })
      end
    end

    context "when exception and invalid argument is passed" do
      let(:ex) { RuntimeError.new("test error") }

      it "raises argument error" do
        expect { HBW.notify(ex, ctx: { user_id: 3 }) }.to raise_error(ArgumentError, "unknown keyword: ctx")
      end
    end

    context "when error_class and error_message is passed" do
      let(:error_class) { "InvalidUserError" }
      let(:error_message) { "user must be hard worker" }

      it "calls notify_raw with error_class, error_message" do
        expect(HBW).to receive(:notify_raw).with(default_args.merge({ error_class: error_class, error_message: error_message }))
        HBW.notify(error_class, error_message)
      end
    end

    context "when only error_class is passed" do
      let(:error_class) { "InvalidUserError" }

      it "raiseds argument error" do
        expect { HBW.notify(error_class) }.to raise_error(ArgumentError, "option_or_error_message must be String-like object, but got ")
      end
    end

    context "when error_class and error_message and other options are passed" do
      let(:error_class) { "InvalidUserError" }
      let(:error_message) { "user must be hard worker" }

      it "calls notify_raw with error_class and error_message and other options" do
        expect(HBW).to receive(:notify_raw).with(default_args.merge({ error_class: error_class, error_message: error_message, context: { user_id: 3 }, notice_only: true }))
        HBW.notify(error_class, error_message, context: { user_id: 3 }, notice_only: true)
      end
    end

    context "when error_class and invalid argument is passed" do
      let(:error_class) { "InvalidUserError" }
      let(:error_message) { "user must be hard worker" }

      it "raises argument error" do
        expect { HBW.notify(error_class, error_message, ctx: { user_id: 3 }) }.to raise_error(ArgumentError, "unknown keyword: ctx")
      end
    end
  end

  describe ".notify_raw" do
    context "when Honeybadger is used" do
      before do
        allow(HBW).to receive(:should_use_honeybadger?).and_return(true)
      end

      context "when only exception is passed" do
        let(:ex) { RuntimeError.new("test error") }

        it "calls Honeybadger.notify with exception" do
          expect(HBW).to receive(:honeybadger_notify).with(ex, {})
          HBW.notify_raw(ex)
        end
      end

      context "when exception and other options are passed" do
        let(:ex) { RuntimeError.new("test error") }

        it "calls Honeybadger.notify with exception" do
          expect(HBW).to receive(:honeybadger_notify).with(ex, { context: { user_id: 3 } })
          HBW.notify_raw(ex, context: { user_id: 3 })
        end
      end

      context "when exception and notice_only is passed" do
        let(:ex) { RuntimeError.new("test error") }

        it "calls Honeybadger.notify with exception" do
          expect(HBW).to receive(:honeybadger_notify).with(ex, { error_message: "[Notice Only] RuntimeError: #{ex.message}", context: { user_id: 3 } })
          HBW.notify_raw(ex, context: { user_id: 3 }, notice_only: true)
        end
      end

      context "when error_class and error_message are passed" do
        let(:error_class) { "InvalidUserError" }
        let(:error_message) { "user must be hard worker" }

        it "calls Honeybadger.notify with exception" do
          expect(HBW).to receive(:honeybadger_notify).with({ error_class: error_class, error_message: error_message, context: { user_id: 3 } })
          HBW.notify_raw(error_class: error_class, error_message: error_message, context: { user_id: 3 })
        end
      end

      context "when error_class and error_message and notice_only are passed" do
        let(:error_class) { "InvalidUserError" }
        let(:error_message) { "user must be hard worker" }

        it "calls Honeybadger.notify with exception" do
          expect(HBW).to receive(:honeybadger_notify).with({ error_class: error_class, error_message: "[Notice Only] Notice: #{error_message}", context: { user_id: 3 } })
          HBW.notify_raw(error_class: error_class, error_message: error_message, context: { user_id: 3 }, notice_only: true)
        end
      end
    end

    context "when Honeybadger is not used" do
      before do
        allow(HBW).to receive(:should_use_honeybadger?).and_return(false)
      end

      context "when raise_development is true" do
        context "when only exception is passed" do
          let(:ex) { RuntimeError.new("test error") }

          it "raises exception" do
            expect { HBW.notify_raw(ex) }.to raise_error(ex)
          end
        end

        context "when exception and notice_only is specified" do
          let(:ex) { RuntimeError.new("test error") }

          it "raises exception" do
            expect { HBW.notify_raw(ex, notice_only: true) }.to raise_error(RuntimeError, "[Notice Only] RuntimeError: #{ex.message}")
          end
        end

        context "when error_class and error_message are specified" do
          let(:error_class) { "InvalidUserError" }
          let(:error_message) { "user must be hard worker" }

          it "raises exception" do
            expect { HBW.notify_raw(error_class: error_class, error_message: error_message) }.to raise_error(RuntimeError, error_message)
          end
        end

        context "when error_class and error_message and notice_only are specified" do
          let(:error_class) { "InvalidUserError" }
          let(:error_message) { "user must be hard worker" }

          it "raises exception" do
            expect { HBW.notify_raw(error_class: error_class, error_message: error_message, notice_only: true) }.to raise_error(RuntimeError, "[Notice Only] Notice: #{error_message}")
          end
        end
      end

      context "when raise_development is false" do
        context "when exception is passed" do
          let(:ex) { RuntimeError.new("test error") }

          it "raises no error" do
            expect { HBW.notify_raw(ex, raise_development: false) }.to_not raise_error
          end
        end

        context "when error_class and error_message are specified" do
          let(:error_class) { "InvalidUserError" }
          let(:error_message) { "user must be hard worker" }

          it "raises no error" do
            expect { HBW.notify_raw(error_class: error_class, error_message: error_message, raise_development: false) }.to_not raise_error
          end
        end
      end
    end
  end
end
