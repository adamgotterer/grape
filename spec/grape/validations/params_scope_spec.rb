require 'spec_helper'

describe Grape::Validations::ParamsScope do
  subject do
    Class.new(Grape::API)
  end

  def app
    subject
  end

  context 'setting description' do
    [:desc, :description].each do |description_type|
      it "allows setting #{description_type}" do
        subject.params do
          requires :int, type: Integer, description_type => 'My very nice integer'
        end
        subject.get '/single' do
          'int works'
        end
        get '/single', int: 420
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('int works')
      end
    end
  end

  context 'array without coerce type explicitly given' do
    it 'sets the type based on first element' do
      subject.params do
        requires :periods, type: Array, values: -> { %w(day month) }
      end
      subject.get('/required') { 'required works' }

      get '/required', periods: %w(day month)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('required works')
    end

    it 'fails to call API without Array type' do
      subject.params do
        requires :periods, type: Array, values: -> { %w(day month) }
      end
      subject.get('/required') { 'required works' }

      get '/required', periods: 'day'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('periods is invalid')
    end

    it 'raises exception when values are of different type' do
      expect do
        subject.params { requires :numbers, type: Array, values: [1, 'definitely not a number', 3] }
      end.to raise_error Grape::Exceptions::IncompatibleOptionValues
    end

    it 'raises exception when range values have different endpoint types' do
      expect do
        subject.params { requires :numbers, type: Array, values: 0.0..10 }
      end.to raise_error Grape::Exceptions::IncompatibleOptionValues
    end
  end

  context 'with range values' do
    context "when left range endpoint isn't #kind_of? the type" do
      it 'raises exception' do
        expect do
          subject.params { requires :latitude, type: Integer, values: -90.0..90 }
        end.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end

    context "when right range endpoint isn't #kind_of? the type" do
      it 'raises exception' do
        expect do
          subject.params { requires :latitude, type: Integer, values: -90..90.0 }
        end.to raise_error Grape::Exceptions::IncompatibleOptionValues
      end
    end

    context 'when both range endpoints are #kind_of? the type' do
      it 'accepts values in the range' do
        subject.params do
          requires :letter, type: String, values: 'a'..'z'
        end
        subject.get('/letter') { params[:letter] }

        get '/letter', letter: 'j'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('j')
      end

      it 'rejects values outside the range' do
        subject.params do
          requires :letter, type: String, values: 'a'..'z'
        end
        subject.get('/letter') { params[:letter] }

        get '/letter', letter: 'J'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('letter does not have a valid value')
      end
    end
  end
end
