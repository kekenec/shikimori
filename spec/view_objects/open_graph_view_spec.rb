describe OpenGraphView do
  include_context :seeds
  include_context :view_object_warden_stub

  let(:view) { described_class.new }

  describe '#site_name' do
    before { allow(view.h).to receive(:ru_host?).and_return is_ru_host }
    subject { view.site_name }

    context 'ru_host' do
      let(:is_ru_host) { true }
      it { is_expected.to eq 'Шикимори' }
    end

    context 'not ru_host' do
      let(:is_ru_host) { false }
      it { is_expected.to eq 'Shikimori' }
    end
  end

  describe '#canonical_url' do
    subject { view.canonical_url }

    context 'no page param' do
      before { allow(view.h.request).to receive(:url).and_return url }
      let(:url) { 'http://zzz.com?123#45' }

      it { is_expected.to eq 'http://zzz.com' }
      it { is_expected.to be_html_safe }
    end

    context 'page param' do
      before do
        allow(view.h).to receive(:params).and_return params
        allow(view.h).to receive(:current_url) { |hash| view.h.url_for(params.merge(hash)) }
      end

      let(:params) do
        {
          controller: 'animes_collection',
          action: 'index',
          page: 2,
          klass: 'anime'
        }
      end

      it { is_expected.to eq '/animes' }
      it { is_expected.to be_html_safe }
    end
  end

  describe '#page_title, #meta_title, #headline' do
    context 'has title' do
      before do
        view.page_title = 'test'
        view.page_title = '123'
      end

      it { expect(view.meta_title).to eq '<title>123 / test</title>' }
      it { expect(view.meta_title).to be_html_safe }
      it { expect(view.headline).to eq '123' }
    end

    context 'no title' do
      before { allow(view.h).to receive(:ru_host?).and_return is_ru_host }
      let(:is_ru_host) { true }

      context 'ru_host' do
        it { expect(view.meta_title).to eq '<title>Шикимори</title>' }
      end

      context 'not ru_host' do
        let(:is_ru_host) { false }
        it { expect(view.meta_title).to eq '<title>Shikimori</title>' }
      end

      it { expect { view.headline }.to raise_error 'open_graph.page_title is not set' }
      it { expect { view.headline false }.to raise_error 'open_graph.page_title is not set' }
      it { expect(view.headline true).to eq view.site_name }
    end

    context 'development' do
      before do
        view.page_title = 'test'
        view.page_title = '123'
        allow(Rails.env).to receive(:development?).and_return true
      end

      it { expect(view.meta_title).to eq '<title>[DEV] 123 / test</title>' }
    end
  end

  describe '#notice, #description' do
    before do
      view.notice = notice
      view.description = description
    end
    let(:notice) { '123' }
    let(:description) { '456' }

    it { expect(view.notice).to eq notice }
    it { expect(view.description).to eq description }

    context 'no notice' do
      let(:notice) { nil }
      it { expect(view.notice).to eq description }
      it { expect(view.description).to eq description }
    end

    context 'no description' do
      let(:description) { nil }
      it { expect(view.notice).to eq notice }
      it { expect(view.description).to eq notice }
    end
  end

  describe '#meta_keywords' do
    before { view.keywords = keywords }
    subject { view.meta_keywords }

    context 'present keywords' do
      let(:keywords) { '456' }
      it { is_expected.to eq "<meta name=\"keywords\" content=\"#{keywords}\">" }
      it { is_expected.to be_html_safe }
    end

    context 'no keywords' do
      let(:keywords) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '#meta_description' do
    before { view.send %i[description= notice=].sample, description }
    subject { view.meta_description }

    context 'present description' do
      let(:description) { '456' }
      it { is_expected.to eq "<meta name=\"description\" content=\"#{description}\">" }
      it { is_expected.to be_html_safe }
    end

    context 'no description' do
      let(:description) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '#meta_robots' do
    before do
      view.noindex = noindex
      view.nofollow = nofollow
    end
    subject { view.meta_robots }

    context 'no noindex, no nofollow' do
      let(:noindex) { false }
      let(:nofollow) { false }

      it { is_expected.to be_nil }
    end

    context 'has noindex, no nofollow' do
      let(:noindex) { true }
      let(:nofollow) { false }

      it { is_expected.to eq '<meta name="robots" content="noindex">' }
      it { is_expected.to be_html_safe }
    end

    context 'no noindex, has nofollow' do
      let(:noindex) { false }
      let(:nofollow) { true }

      it { is_expected.to eq '<meta name="robots" content="nofollow">' }
      it { is_expected.to be_html_safe }
    end

    context 'has noindex, has nofollow' do
      let(:noindex) { true }
      let(:nofollow) { true }

      it { is_expected.to eq '<meta name="robots" content="noindex,nofollow">' }
      it { is_expected.to be_html_safe }

      context 'has another canonical url' do
        before do
          allow(view).to receive(:canonical_url).and_return 'zzz'
          allow(view.h.request).to receive(:url).and_return 'zxc'
        end
        it { is_expected.to be_nil }
      end
    end
  end
end
