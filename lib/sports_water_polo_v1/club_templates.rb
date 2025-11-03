# frozen_string_literal: true

module SportsWaterPoloV1
  module ClubTemplates
    # Template definitions for water polo clubs
    def self.templates
      {
        blank: {
          name: "Blank Club",
          description: "Empty club - set up divisions and teams manually",
          gendered: false,
          gender_options: [],
          generator: ->(club, options) { setup_blank_club(club, options) }
        },
        youth: {
          name: "Youth Club",
          description: "Age-based divisions (4U-18U) with cohorts for graduating classes",
          gendered: true,
          gender_options: [
            { value: 'boys_girls_all', label: 'Boys & Girls at every age' },
            { value: 'boys_girls_mixed', label: 'Boys & Girls for 12U+, Girls/Coed for 10U, coed for younger' },
            { value: 'coed_all', label: 'Coed at every age' }
          ],
          generator: ->(club, options) { setup_youth_club(club, options) }
        },
        high_school: {
          name: "High School",
          description: "Varsity/JV/Frosh competitive levels",
          gendered: true,
          gender_options: [
            { value: 'boys', label: 'Boys / Mens' },
            { value: 'girls', label: 'Girls / Womens' }
          ],
          generator: ->(club, options) { setup_high_school(club, options) }
        }
      }.freeze
    end

    class << self
      # Setup blank club - does nothing, club starts empty
      def setup_blank_club(club, options = {})
        # Intentionally blank - no setup needed
        Rails.logger.info "Blank club setup for #{club.name} - starting empty"
      end

      # Setup youth water polo club
      def setup_youth_club(club, options = {})
        division_config = options[:division_configuration] || options[:gender] || 'boys_girls_mixed'
        Rails.logger.info "Youth club setup for #{club.name} with division_configuration: #{division_config.inspect}"
        cutoff_date = "08-01"

        season_year = options[:season_year]&.to_i || calculate_season_year(cutoff_date)

        division_configs = case division_config
        when 'boys_girls_all'
          Rails.logger.info "Using boys_girls_all_ages"
          build_boys_girls_all_ages(season_year)
        when 'boys_girls_mixed'
          Rails.logger.info "Using boys_girls_mixed"
          build_boys_girls_mixed(season_year)
        when 'coed_all'
          Rails.logger.info "Using coed_all_ages"
          build_coed_all_ages(season_year)
        else
          Rails.logger.info "Using default (boys_girls_mixed)"
          build_boys_girls_mixed(season_year)  # Default
        end

        create_divisions_cohorts_teams(club, division_configs, cutoff_date, season_year)
      end

      # Setup high school water polo
      def setup_high_school(club, options = {})
        division_config = options[:division_configuration] || options[:gender] || 'boys'
        season_year = options[:season_year]&.to_i || calculate_season_year("08-01")
        cutoff_date = "08-01"

        # Map boys/girls to male/female for database
        db_gender = case division_config
        when 'boys' then 'male'
        when 'girls' then 'female'
        else 'coed'
        end

        gender_suffix = case division_config
        when 'boys' then " Boys"
        when 'girls' then " Girls"
        else ""
        end

        ActiveRecord::Base.transaction do
          # Create the season
          season_start = Date.new(season_year - 1, 8, 1)
          season_end = Date.new(season_year, 7, 31)

          season = club.seasons.create!(
            name: "#{season_year - 1}-#{season_year}",
            start_date: season_start,
            end_date: season_end,
            status: 'active'
          )

          club.update!(current_season: season)

          # Create all graduation year cohorts from current seniors through 4 years out
          first_graduating_year = season_year  # Current seniors
          last_graduating_year = season_year + 4  # Current freshmen

          cohorts_by_grad_year = {}

          (first_graduating_year..last_graduating_year).each do |graduating_year|
            # Determine eligibility dates for this graduation year
            # Athletes who graduate in year X are born between Aug 1, (X-19) and July 31, (X-18)
            eligibility_start = Date.new(graduating_year - 19, 8, 1)
            eligibility_end = Date.new(graduating_year - 18, 7, 31)

            cohort_name = case division_config
            when 'boys' then "Boys of #{graduating_year}"
            when 'girls' then "Girls of #{graduating_year}"
            else "Class of #{graduating_year}"
            end

            cohort = club.cohorts.create!(
              sport_year: graduating_year,  # sport_year IS the graduation year
              name: cohort_name,
              eligibility_start_date: eligibility_start,
              eligibility_end_date: eligibility_end,
              allowed_genders: db_gender == 'coed' ? [] : [db_gender]
            )

            cohorts_by_grad_year[graduating_year] = cohort
          end

          # Create single division for high school
          division = club.divisions.create!(
            name: "#{club.name} Varsity Program#{gender_suffix}",
            gender: db_gender,
            min_age: 14,
            max_age: 18,
            cutoff_date: cutoff_date,
            allowed_genders: db_gender == 'coed' ? [] : [db_gender]
          )

          # Assign cohorts to division (high school has grades 9-12, so 4 graduating classes)
          (0..3).each do |years_back|
            graduating_year = season_year + (4 - years_back)
            cohort = cohorts_by_grad_year[graduating_year]

            if cohort
              CohortAssignment.create!(
                season: season,
                cohort: cohort,
                division: division
              )
            end
          end

          # Create teams
          ['Varsity', 'Junior Varsity', 'Frosh'].each_with_index do |level_name, idx|
            team_name = "#{level_name}#{gender_suffix}"
            level_code = ['varsity', 'jv', 'frosh'][idx]

            division.teams.create!(
              name: team_name,
              level: level_code,
              sport_key: club.sport_keys.first,
              sport_version_major: 1,
              allowed_genders: db_gender == 'coed' ? [] : [db_gender]
            )
          end
        end
      end

      private

      def calculate_season_year(cutoff_date)
        today = Date.today
        month, day = cutoff_date.split("-").map(&:to_i)
        cutoff_this_year = Date.new(today.year, month, day)
        today >= cutoff_this_year ? today.year + 1 : today.year
      end

      # Option 1: Boys and Girls at every age (12U+ separate, 10U boys+coed, 8U/6U/4U coed only)
      # 13 divisions total
      def build_boys_girls_all_ages(season_year)
        [
          # 18U, 16U, 14U, 12U: Boys and Girls separate
          { name: "18U Boys", age_group: "18U", gender: "male", min_age: 17, max_age: 18, cohort_birth_years: [season_year - 18, season_year - 17] },
          { name: "18U Girls", age_group: "18U", gender: "female", min_age: 17, max_age: 18, cohort_birth_years: [season_year - 18, season_year - 17] },
          { name: "16U Boys", age_group: "16U", gender: "male", min_age: 15, max_age: 16, cohort_birth_years: [season_year - 16, season_year - 15] },
          { name: "16U Girls", age_group: "16U", gender: "female", min_age: 15, max_age: 16, cohort_birth_years: [season_year - 16, season_year - 15] },
          { name: "14U Boys", age_group: "14U", gender: "male", min_age: 13, max_age: 14, cohort_birth_years: [season_year - 14, season_year - 13] },
          { name: "14U Girls", age_group: "14U", gender: "female", min_age: 13, max_age: 14, cohort_birth_years: [season_year - 14, season_year - 13] },
          { name: "12U Boys", age_group: "12U", gender: "male", min_age: 11, max_age: 12, cohort_birth_years: [season_year - 12, season_year - 11] },
          { name: "12U Girls", age_group: "12U", gender: "female", min_age: 11, max_age: 12, cohort_birth_years: [season_year - 12, season_year - 11] },
          { name: "10U Boys", age_group: "10U", gender: "male", min_age: 9, max_age: 10, cohort_birth_years: [season_year - 10, season_year - 9] },
          { name: "10U Girls", age_group: "10U", gender: "female", min_age: 9, max_age: 10, cohort_birth_years: [season_year - 10, season_year - 9] },
          { name: "8U Boys", age_group: "8U", gender: "male", min_age: 7, max_age: 8, cohort_birth_years: [season_year - 8, season_year - 7] },
          { name: "8U Girls", age_group: "8U", gender: "female", min_age: 7, max_age: 8, cohort_birth_years: [season_year - 8, season_year - 7] },
          { name: "6U Boys", age_group: "6U", gender: "male", min_age: 5, max_age: 6, cohort_birth_years: [season_year - 6, season_year - 5] },
          { name: "6U Girls", age_group: "6U", gender: "female", min_age: 5, max_age: 6, cohort_birth_years: [season_year - 6, season_year - 5] },
          { name: "4U Boys", age_group: "4U", gender: "male", min_age: 3, max_age: 4, cohort_birth_years: [season_year - 4, season_year - 3] },
          { name: "4U Girls", age_group: "4U", gender: "female", min_age: 3, max_age: 4, cohort_birth_years: [season_year - 4, season_year - 3] }
        ]
      end

      # Option 2: Boys/Girls 12U+, Girls/Coed at 10U and below (standard water polo)
      # 13 divisions total
      def build_boys_girls_mixed(season_year)
        [
          # 18U, 16U, 14U, 12U: Boys and Girls separate
          { name: "18U Boys", age_group: "18U", gender: "male", min_age: 17, max_age: 18, cohort_birth_years: [season_year - 18, season_year - 17] },
          { name: "18U Girls", age_group: "18U", gender: "female", min_age: 17, max_age: 18, cohort_birth_years: [season_year - 18, season_year - 17] },
          { name: "16U Boys", age_group: "16U", gender: "male", min_age: 15, max_age: 16, cohort_birth_years: [season_year - 16, season_year - 15] },
          { name: "16U Girls", age_group: "16U", gender: "female", min_age: 15, max_age: 16, cohort_birth_years: [season_year - 16, season_year - 15] },
          { name: "14U Boys", age_group: "14U", gender: "male", min_age: 13, max_age: 14, cohort_birth_years: [season_year - 14, season_year - 13] },
          { name: "14U Girls", age_group: "14U", gender: "female", min_age: 13, max_age: 14, cohort_birth_years: [season_year - 14, season_year - 13] },
          { name: "12U Boys", age_group: "12U", gender: "male", min_age: 11, max_age: 12, cohort_birth_years: [season_year - 12, season_year - 11] },
          { name: "12U Girls", age_group: "12U", gender: "female", min_age: 11, max_age: 12, cohort_birth_years: [season_year - 12, season_year - 11] },
          # 10U: Boys and Coed
          { name: "10U Girls", age_group: "10U", gender: "female", min_age: 9, max_age: 10, cohort_birth_years: [season_year - 10, season_year - 9] },
          { name: "10U Coed", age_group: "10U", gender: "coed", min_age: 9, max_age: 10, cohort_birth_years: [season_year - 10, season_year - 9] },
          # 8U, 6U, 4U: Only Coed
          { name: "8U Coed", age_group: "8U", gender: "coed", min_age: 7, max_age: 8, cohort_birth_years: [season_year - 8, season_year - 7] },
          { name: "6U Coed", age_group: "6U", gender: "coed", min_age: 5, max_age: 6, cohort_birth_years: [season_year - 6, season_year - 5] },
          { name: "4U Coed", age_group: "4U", gender: "coed", min_age: 3, max_age: 4, cohort_birth_years: [season_year - 4, season_year - 3] }
        ]
      end

      # Option 3: Coed at every age (18U through 4U)
      # 8 divisions total
      def build_coed_all_ages(season_year)
        [
          { name: "18U Coed", age_group: "18U", gender: "coed", min_age: 17, max_age: 18, cohort_birth_years: [season_year - 18, season_year - 17] },
          { name: "16U Coed", age_group: "16U", gender: "coed", min_age: 15, max_age: 16, cohort_birth_years: [season_year - 16, season_year - 15] },
          { name: "14U Coed", age_group: "14U", gender: "coed", min_age: 13, max_age: 14, cohort_birth_years: [season_year - 14, season_year - 13] },
          { name: "12U Coed", age_group: "12U", gender: "coed", min_age: 11, max_age: 12, cohort_birth_years: [season_year - 12, season_year - 11] },
          { name: "10U Coed", age_group: "10U", gender: "coed", min_age: 9, max_age: 10, cohort_birth_years: [season_year - 10, season_year - 9] },
          { name: "8U Coed", age_group: "8U", gender: "coed", min_age: 7, max_age: 8, cohort_birth_years: [season_year - 8, season_year - 7] },
          { name: "6U Coed", age_group: "6U", gender: "coed", min_age: 5, max_age: 6, cohort_birth_years: [season_year - 6, season_year - 5] },
          { name: "4U Coed", age_group: "4U", gender: "coed", min_age: 3, max_age: 4, cohort_birth_years: [season_year - 4, season_year - 3] }
        ]
      end

      def create_divisions_cohorts_teams(club, division_configs, cutoff_date, season_year)
        sport_key = club.sport_keys.first

        ActiveRecord::Base.transaction do
          # Create the season
          season_start = Date.new(season_year - 1, 8, 1)  # Season starts August 1 of previous year
          season_end = Date.new(season_year, 7, 31)       # Season ends July 31 of season year

          season = club.seasons.create!(
            name: "#{season_year - 1}-#{season_year}",
            start_date: season_start,
            end_date: season_end,
            status: 'active'
          )

          # Set this as the club's current season
          club.update!(current_season: season)

          # Create all graduation year cohorts from current seniors through future years
          # Current seniors graduate in the season_year (e.g., if season_year is 2026, seniors graduate in 2026)
          # 4U kids this year (season_year 2026) will be 18 on 8/1/2041, so they graduate in 2042
          first_graduating_year = season_year  # Current seniors
          last_graduating_year = season_year + 18  # Current 4U kids (who will be 18 in 18 years)

          cohorts_by_grad_year = {}

          (first_graduating_year..last_graduating_year).each do |graduating_year|
            # Determine eligibility dates for this graduation year
            # Athletes who graduate in year X are born between Aug 1, (X-19) and July 31, (X-18)
            # Example: Class of 2026 is born Aug 1, 2007 through July 31, 2008
            eligibility_start = Date.new(graduating_year - 19, 8, 1)
            eligibility_end = Date.new(graduating_year - 18, 7, 31)

            # Create cohorts for each gender configuration
            ['male', 'female', 'coed'].each do |gender|
              cohort_name = case gender
              when 'male' then "Boys of #{graduating_year}"
              when 'female' then "Girls of #{graduating_year}"
              else "Class of #{graduating_year}"
              end

              cohort = club.cohorts.create!(
                sport_year: graduating_year,  # sport_year IS the graduation year
                name: cohort_name,
                eligibility_start_date: eligibility_start,
                eligibility_end_date: eligibility_end,
                allowed_genders: gender == 'coed' ? [] : [gender]
              )

              cohorts_by_grad_year[graduating_year] ||= {}
              cohorts_by_grad_year[graduating_year][gender] = cohort
            end
          end

          # Create divisions and assign cohorts
          division_configs.each do |config|
            division = club.divisions.create!(
              name: config[:name],
              age_group: config[:age_group],
              gender: config[:gender],
              min_age: config[:min_age],
              max_age: config[:max_age],
              cutoff_date: cutoff_date,
              allowed_genders: config[:gender] == "coed" ? [] : [config[:gender]]
            )

            # Assign appropriate cohorts to this division
            # For example, 18U division gets cohorts for kids who will be 17-18 during the season
            # That means they graduate in season_year and season_year + 1
            config[:cohort_birth_years].each do |birth_year|
              graduating_year = birth_year + 18

              # Get the cohort for this graduating year and gender
              cohort = cohorts_by_grad_year.dig(graduating_year, config[:gender])

              if cohort
                CohortAssignment.create!(
                  season: season,
                  cohort: cohort,
                  division: division
                )
              end
            end

            # Create default A team
            division.teams.create!(
              name: "#{config[:name]} A",
              level: "A",
              sport_key: sport_key,
              sport_version_major: 1,
              allowed_genders: config[:gender] == "coed" ? [] : [config[:gender]]
            )
          end
        end
      end
    end
  end
end
