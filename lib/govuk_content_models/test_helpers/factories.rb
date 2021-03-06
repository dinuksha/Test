require "factory_girl"
require "answer_edition"
require "artefact"
require "tag"
require "user"

FactoryGirl.define do
  factory :user do
    sequence(:uid) { |n| "uid-#{n}"}
    sequence(:name) { |n| "Joe Bloggs #{n}" }
    sequence(:email) { |n| "joe#{n}@bloggs.com" }
    if defined?(GDS::SSO::Config)
      # Grant permission to signin to the app using the gem
      permissions { ["signin"] }
    end
  end

  factory :disabled_user, parent: :user do
    disabled true
  end

  factory :downtime do
    message "This service will be unavailable between 3:00pm and 6:00pm tomorrow"
    start_time (Date.today + 1).to_time + (15 * 60 * 60)
    end_time (Date.today + 1).to_time + (18 * 60 * 60)
    artefact
  end

  factory :tag do
    sequence(:tag_id) { |n| "crime-and-justice-#{n}" }
    sequence(:title) { |n| "The title #{n}" }
    tag_type "section"

    trait :draft do
      state "draft"
    end

    trait :live do
      state "live"
    end

    factory :draft_tag, traits: [:draft]
    factory :live_tag, traits: [:live]
  end

  factory :artefact do
    sequence(:name) { |n| "Artefact #{n}" }
    sequence(:slug) { |n| "slug-#{n}" }
    kind            Artefact::FORMATS.first
    owning_app      'publisher'

    trait :whitehall do
      sequence(:slug) {|n| "government/slug--#{n}"}
      owning_app      "whitehall"
      kind            Artefact::FORMATS_BY_DEFAULT_OWNING_APP["whitehall"].first
    end

    trait :with_published_edition do
      after(:create) {|object|
        self.create("#{object.kind}_edition".to_sym, panopticon_id: object.id, slug: object.slug, state: "published")
      }
    end

    trait :non_publisher do
      kind            'smart-answer'
      owning_app      'smart-answers'
    end

    trait :draft do
      state "draft"
    end

    trait :live do
      state "live"
    end

    trait :archived do
      state "archived"
    end

    factory :draft_artefact, traits: [:draft]
    factory :live_artefact, traits: [:live]
    factory :archived_artefact, traits: [:archived]

    factory :live_artefact_with_edition, traits: [:live, :with_published_edition]

    factory :whitehall_draft_artefact, traits: [:whitehall, :draft]
    factory :whitehall_live_artefact, traits: [:whitehall, :live]
    factory :whitehall_archived_artefact, traits: [:whitehall, :archived]

    factory :non_publisher_artefact, traits: [:non_publisher]
  end

  factory :edition, class: AnswerEdition do
    panopticon_id {
        a = create(:artefact)
        a.id
      }

    sequence(:slug) { |n| "slug-#{n}" }
    sequence(:title) { |n| "A key answer to your question #{n}" }

    after :build do |ed|
      if previous = ed.series.order(version_number: "desc").first
        ed.version_number = previous.version_number + 1
      end
    end

    trait :scheduled_for_publishing do
      state 'scheduled_for_publishing'
      publish_at 1.day.from_now
    end

    trait :published do
      state 'published'
    end
  end
  factory :answer_edition, parent: :edition do
  end

  factory :help_page_edition, :parent => :edition, :class => 'HelpPageEdition' do
  end

  factory :campaign_edition, :parent => :edition, :class => 'CampaignEdition' do
  end

  factory :completed_transaction_edition, :parent => :edition, :class => 'CompletedTransactionEdition' do
  end

  factory :video_edition, parent: :edition, :class => 'VideoEdition' do
  end

  factory :business_support_edition, :parent => :edition, :class => "BusinessSupportEdition" do
  end

  factory :guide_edition, :parent => :edition, :class => "GuideEdition" do
    sequence(:title)  { |n| "Test guide #{n}" }
  end

  factory :programme_edition, :parent => :edition, :class => "ProgrammeEdition" do
    sequence(:title) { |n| "Test programme #{n}" }
  end

  factory :programme_edition_with_multiple_parts, parent: :programme_edition do
    after :create do |getp|
      getp.parts.build(title: "PART !", body: "This is some programme version text.",
                       slug: "part-one")
      getp.parts.build(title: "PART !!",
                       body: "This is some more programme version text.",
                       slug: "part-two")
    end
  end

  factory :guide_edition_with_two_parts, parent: :guide_edition do
    after :create do |getp|
      getp.parts.build(title: "PART !", body: "This is some version text.",
                       slug: "part-one")
      getp.parts.build(title: "PART !!",
                       body: "This is some more version text.",
                       slug: "part-two")
    end
  end

  factory :guide_edition_with_two_govspeak_parts, parent: :guide_edition do
    after :create do |getp|
      getp.parts.build(title: "Some Part Title!",
                       body: "This is some **version** text.", slug: "part-one")
      getp.parts.build(title: "Another Part Title",
                       body: "This is [link](http://example.net/) text.",
                       slug: "part-two")
    end
  end

  factory :local_transaction_edition, :parent => :edition, :class => "LocalTransactionEdition" do
    sequence(:lgsl_code) { |nlgsl| nlgsl }
    introduction { "Test introduction" }
    more_information { "This is more information" }
    need_to_know "This service is only available in England and Wales"
  end

  factory :transaction_edition, :parent => :edition, :class => "TransactionEdition" do
    introduction { "Test introduction" }
    more_information { "This is more information" }
    need_to_know "This service is only available in England and Wales"
    link "http://continue.com"
    will_continue_on "To be continued..."
    alternate_methods "Method A or Method B"
  end

  factory :licence_edition, :parent => :edition, :class => "LicenceEdition" do
    licence_identifier "AB1234"
  end

  factory :local_service do |ls|
    ls.sequence(:lgsl_code)
    providing_tier { %w{district unitary county} }
  end

  factory :local_authority do
    name "Some Council"
    sequence(:snac) {|n| "%02dAA" % n }
    sequence(:local_directgov_id)
    tier "county"
  end

  factory :local_authority_with_contact, parent: :local_authority do
    contact_address ["line one", "line two", "line three"]
    contact_url "http://www.magic.com/contact"
    contact_phone "0206778654"
    contact_email "contact@local.authority.gov.uk"
  end

  factory :local_interaction do
    association :local_authority
    url "http://some.council.gov/do.html"
    sequence(:lgsl_code) {|n| 120 + n }
    lgil_code 0
  end

  factory :place_edition do
    title "Far far away"
    introduction "Test introduction"
    more_information "More information"
    need_to_know "This service is only available in England and Wales"
    place_type "Location location location"
  end

  factory :curated_list do
    sequence(:slug) { |n| "slug-#{n}" }
  end

  factory :travel_advice_edition do
    sequence(:country_slug) {|n| "test-country-#{n}" }
    sequence(:title) {|n| "Test Country #{n}" }
    change_description "Stuff changed"
  end

  # These factories only work when used with FactoryGirl.create
  factory :draft_travel_advice_edition, :parent => :travel_advice_edition do
  end
  factory :published_travel_advice_edition, :parent => :travel_advice_edition do
    after :create do |tae|
      tae.published_at ||= Time.zone.now.utc
      tae.state = 'published'
      tae.save!
    end
  end
  factory :archived_travel_advice_edition, :parent => :travel_advice_edition do
    after :create do |tae|
      tae.state = 'archived'
      tae.save!
    end
  end

  factory :rendered_specialist_document do
    sequence(:slug) {|n| "test-rendered-specialist-document-#{n}" }
    sequence(:title) {|n| "Test Rendered Specialist Document #{n}" }
    summary "My summary"
    body "<p>My body</p>"
    details({
      "opened_date" => "2013-04-20",
      "market_sector" => "some-market-sector",
      "case_type" => "a-case-type",
      "case_state" => "open",
    })
  end

  factory :rendered_manual do
    sequence(:slug) {|n| "test-rendered-manual-#{n}" }
    sequence(:title) {|n| "Test Rendered Manual #{n}" }
    summary "My summary"
  end

  factory :simple_smart_answer_edition, :parent => :edition, :class => "SimpleSmartAnswerEdition" do
    title "Simple smart answer"
    body "Introduction to the smart answer"
  end
end
