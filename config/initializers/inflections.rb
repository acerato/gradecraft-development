# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end
#
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "LMS"
  inflect.acronym "LTI"
  inflect.acronym "API"
  inflect.acronym "OAuth"
  inflect.irregular "criterion", "criteria"
  inflect.irregular "TA", "TA"
end
