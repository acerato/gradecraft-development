@gradecraft.controller 'GradeRubricCtrl', ['$scope', 'Restangular', 'RubricService', '$q', ($scope, Restangular, RubricService, $q) ->

  $scope.assignment = RubricService.assignment
  $scope.courseBadges = RubricService.badges
  $scope.criteria = RubricService.criteria
  $scope.criterionGrades = RubricService.criterionGrades
  $scope.grade = RubricService.grade
  $scope.gradeStatusOptions = RubricService.gradeStatusOptions

  RubricService.getAssignment(window.location)

  # Criterion factory is dependent on CriterionGrades existing in scope
  $scope.init = ()->
    $q.all([RubricService.getCriterionGrades($scope.assignment)])

  $scope.init().then(()->
    RubricService.getCriteria($scope.assignment, $scope)
  )

  RubricService.getBadges()
  RubricService.getGrade($scope.assignment)

  $scope.pointsPossible = ()->
    RubricService.pointsPossible()

  # distill key/value pairs for criterion ids and relative order
  $scope.pointsAssigned = ()->
    points = 0
    angular.forEach($scope.criteria, (criterion, index)->
      points += criterion.max_points if criterion.max_points
    )
    points or 0

  $scope.pointsAdjustment = ()->
    parseInt($scope.grade.points_adjustment) || 0

  $scope.pointsAdjusted = ()->
    $scope.pointsAdjustment() != 0

  $scope.pointsDifference = ()->
    $scope.pointsPossible() - $scope.pointsGiven()

  $scope.pointsRemaining = ()->
    pointsRemaining = $scope.pointsDifference()
    if pointsRemaining > 0 then pointsRemaining else 0

  # Methods for identifying point deficit/overage
  $scope.pointsMissing = ()->
    $scope.pointsDifference() > 0 and $scope.pointsGiven() > 0

  $scope.pointsSatisfied = ()->
    $scope.pointsDifference() == 0 and $scope.pointsGiven() > 0

  $scope.pointsOverage = ()->
    $scope.pointsDifference() < 0

  # count how many levels have been selected in the UI
  $scope.selectedLevels = ()->
    levels = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        levels.push criterion.selectedLevel
    )
    levels


  # count how many levels have been selected in the UI
  $scope.selectedLevelIds = ()->
    levelIds = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        levelIds.push criterion.selectedLevel.id
    )
    levelIds

  # ids of all the criteria in the rubric
  $scope.allCriterionIds = ()->
    criterionIds = []
    angular.forEach($scope.criteria, (criterion, index)->
      criterionIds.push criterion.id
    )
    criterionIds

  # count how many points have been given from those levels
  $scope.pointsGiven = ()->
    points = 0
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        points += criterion.selectedLevel.points
    )
    points

  $scope.pointsGivenAfterAdjustment = ()->
    $scope.pointsGiven() + $scope.pointsAdjustment()

  $scope.gradedCriteria = ()->
    criteria = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        criteria.push criterion
    )
    criteria

  $scope.selectedCriteria = ()->
    criteria = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        criteria.push criterion
    )
    $scope.selectedCriteria = criteria
    criteria

  # Patch: (TODO test and then remove gradedCriteriaParams)
  # For params submitted, we want to include criteria with
  # comments but no selected level
  $scope.criteriaParams = ()->
    params = []
    angular.forEach($scope.criteria, (criterion, index)->
      # get params just from the criterion object
      criterionParams = $scope.criterionOnlyParams(criterion,index)

      # add params from the level if a level has been selected
      if criterion.selectedLevel
        jQuery.extend(criterionParams, $scope.gradedLevelParams(criterion))

      # create params for the rubric grade regardless
      params.push criterionParams
    )
    params

  $scope.gradedCriteriaParams = ()->
    params = []
    angular.forEach($scope.gradedCriteria(), (criterion, index)->
      # get params just from the criterion object
      criterionParams = $scope.criterionOnlyParams(criterion,index)

      # add params from the level if a level has been selected
      if criterion.selectedLevel
        jQuery.extend(criterionParams, $scope.gradedLevelParams(criterion))

      # create params for the rubric grade regardless
      params.push criterionParams
    )
    params

  # params for just the criterion
  $scope.criterionOnlyParams = (criterion,index)->
    {
      criterion_name:        criterion.name,
      criterion_description: criterion.description,
      max_points:            criterion.max_points,
      order:                 index,
      criterion_id:          criterion.id,
      comments:              criterion.comments
    }

  # additional level params if a level is selected
  $scope.gradedLevelParams = (criterion) ->
    {
      level_name:        criterion.selectedLevel.name,
      level_description: criterion.selectedLevel.description,
      points:            criterion.selectedLevel.points,
      level_id:          criterion.selectedLevel.id
    }

  $scope.levelBadgesParams = ()->
    params = []
    angular.forEach($scope.gradedCriteria(), (criterion, index)->
      # grab the selected level for the active criterion
      level = criterion.selectedLevel
      angular.forEach(level.badges, (badge, index)->
        params.push {
          name:         badge.name,
          level_id:     level.id,
          criterion_id: level.criterion_id,
          badge_id:     badge.badge.id,
          description:  badge.description,
          point_total:  badge.point_total,
          icon:         badge.icon,
          multiple:     badge.multiple
        }
      )
    )
    return params

  $scope.gradeParams = ()->
    {
      raw_score: $scope.pointsGiven(),
      feedback: $scope.grade.feedback,
      status:   $scope.grade.status,
      points_adjustment: $scope.grade.points_adjustment,
      points_adjustment_feedback: $scope.grade.points_adjustment_feedback
    }

  # Document any updates to this format in the specs: /spec/support/api_calls/rubric_grade_put.rb
  # student_id or group_id is now passed through the route, see RubricService.putRubricGradeSubmission
  $scope.gradedRubricParams = ()->
    {
      points_possible:  $scope.pointsPossible(),
      criterion_grades: $scope.criteriaParams(),
      level_badges:     $scope.levelBadgesParams(),
      level_ids:        $scope.selectedLevelIds(),
      criterion_ids:    $scope.allCriterionIds(),
      grade:            $scope.gradeParams(),
    }

  $scope.submitGrade = (returnURL)->
    if !$scope.grade.status
      return alert "You must select a grade status before you can submit this grade"
    if confirm "Are you sure you want to submit the grade for this assignment?"
      RubricService.putRubricGradeSubmission($scope.assignment, $scope.gradedRubricParams(), returnURL)

  $scope.froalaOptions = {
    inlineMode: false,
    minHeight: 100,
    buttons: [
      "bold", "italic", "underline", "strikeThrough",
      "insertOrderedList", "insertUnorderedList"
    ]
  }

  $scope.froalaSummaryOptions = {
    inlineMode: false,
    minHeight: 100,
    buttons: [
      'fullscreen', 'bold', 'italic', 'underline', 'strikeThrough', 'subscript',
      'superscript', 'fontFamily', 'fontSize', 'sep', 'inlineStyle', 'blockStyle',
      'sep', 'formatBlock', 'align', 'insertOrderedList', 'insertUnorderedList',
      'outdent', 'indent', 'insertHorizontalRule', 'createLink', 'undo', 'redo',
      'removeFormat', 'selectAll'
    ]
  }
]
