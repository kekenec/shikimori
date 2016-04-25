describe Character do
  describe 'relations' do
    it { is_expected.to have_many :person_roles }
    it { is_expected.to have_many :animes }
    it { is_expected.to have_many :mangas }
    it { is_expected.to have_many :persons }

    it { is_expected.to have_many :persons }
    it { is_expected.to have_many :japanese_roles }
    it { is_expected.to have_many :seyu }

    it { is_expected.to have_attached_file :image }

    it { is_expected.to have_many :cosplay_gallery_links }
    it { is_expected.to have_many :cosplay_galleries }

    it { is_expected.to have_many :topics }
  end
end
