describe Entry do
  describe 'relations' do
    it { should belong_to :section }
    it { should belong_to :linked }
    it { should belong_to :user }
    it { should have_many :views }
    it { should have_many :messages }
  end

  context 'hooks' do
    let(:user) { create :user }
    let(:images) { create_list :user_image, 4, user: user, linked_type: 'Entry' }
    let(:entry) { create :entry, text: 'text', user: user, value: "#{images[0].id},#{images[1].id}" }

    describe 'append_wall' do
      it 'wall tag is appended' do
        expect(entry.text).to eq "text\n[wall][url=#{images[0].image.url :original, false}][poster]#{images[0].image.url :preview, false}[/poster][/url][url=#{images[1].image.url :original, false}][poster]#{images[1].image.url :preview, false}[/poster][/url][/wall]"
      end
    end

    describe 'destroy_images' do
      before { entry }
      it 'all images are destroyed' do
        expect{entry.destroy}.to change(UserImage, :count).by -2
      end
    end

    describe 'claim_images' do
      before { entry }
      it 'all images are claimed' do
        expect(images[0].reload.linked).to eq entry
      end
    end

    describe 'unclaim_images' do
      let(:entry) { create :entry, text: 'text', user: user, value: "#{images[0].id},#{images[1].id},#{images[2].id},#{images[3].id}" }
      before { entry }

      it 'unused images are destroyed' do
        expect {
          entry.user_image_ids = [images[0].id, images[1].id]
          entry.save
        }.to change(UserImage, :count).by -2
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create :user }
    let(:user2) { create :user }
    let(:entry) { create :entry, user: user }

    describe 'user_images' do
      let(:images) { create_list :user_image, 3, user: user }
      let(:entry) { create :entry, user: user, value: "#{images[0].id},#{images[2].id},#{images[1].id}" }

      it 'returns user images stored in value in correct order' do
        expect(entry.user_images).to eq [images[0], images[2], images[1]]
      end
    end

    describe 'comment is deleted' do
      it 'updated_at is set to created_at of last comment' do
        first = second = third = nil
        Comment.wo_antispam do
          first = create :comment, commentable: entry, created_at: DateTime.now - 2.days, body: 'first'
          second = create :comment, commentable: entry, created_at: DateTime.now - 1.day, body: 'second'
          third = create :comment, commentable: entry, created_at: DateTime.now - 30.minutes, body: 'third'
        end
        third.destroy
        expect(Entry.last.updated_at.to_i).to eq(second.created_at.to_i)
      end
    end

    describe 'comments selected with viewed flag' do
      before do
        @comment = create :comment, commentable: entry, user: user
      end

      it 'false' do
        expect(entry.comments.with_viewed(user2).first.viewed?).to be_falsy
      end

      it 'true' do
        create :comment_view, comment: @comment, user: user2
        expect(entry.comments(user2).first.viewed?).to be_truthy
      end
    end
  end

  context 'permissions' do
    let(:user) { build_stubbed :user, :user }
    let(:entry) { build_stubbed :entry, user: user }

    pending 'ability specs'
  end
end
