@gradecraft.controller 'RubricCtrl', ($scope, Restangular, $http) -> 

  INTEGER_REGEXP = /^\-?\d+$/
  Restangular.setRequestSuffix('.json')
  $scope.metrics = []
  $scope.courseBadgesArray = []
  $scope.courseBadges = {}
  $scope.savedMetricCount = 0

  $scope.init = (rubricId, pointTotal, metrics, courseBadges)->
    $scope.rubricId = rubricId
    $scope.pointTotal = parseInt(pointTotal)
    $scope.addCourseBadges(courseBadges)
    $scope.addMetrics(metrics)

  # distill key/value pairs for metric ids and relative order
  $scope.pointsAssigned = ()->
    points = 0
    angular.forEach($scope.metrics, (metric, index)->
      points += metric.max_points if metric.max_points
    )
    points or 0

  $scope.pointsDifference = ()->
    $scope.pointTotal - $scope.pointsAssigned()
 
  $scope.pointsRemaining = ()->
    pointsRemaining = $scope.pointsDifference()
    if pointsRemaining > 0 then pointsRemaining else 0

  # Methods for identifying point deficit/overage
  $scope.pointsMissing = ()->
    $scope.pointsDifference() > 0 and $scope.pointsAssigned() > 0

  # check whether points overview is hidden
  # $scope.pointsOverviewHidden = ()->
  #  element = angular.element(document.querySelector('#points-overview'))
  #  element.is('visible')

  $scope.pointsSatisfied = ()->
    $scope.pointsDifference() == 0 and $scope.pointsAssigned() > 0

  $scope.pointsOverage = ()->
    $scope.pointsDifference() < 0

  $scope.showMetric = (attrs)->
    new MetricPrototype(attrs)

  $scope.countSavedMetric = () ->
    $scope.savedMetricCount += 1

  # Badge Section
  CourseBadgePrototype = (attrs={})->
    this.id = attrs.id
    this.name = attrs.name
    this.description = attrs.description
    this.point_total = attrs.point_total
    this.icon = attrs.icon
    this.multiple = attrs.multiple

  CourseBadgePrototype.prototype = {}

  $scope.addCourseBadges = (courseBadges)->
    angular.forEach(courseBadges, (em, index)->
      courseBadge = new CourseBadgePrototype(em)
      $scope.courseBadgesArray.push courseBadge
    )

    angular.forEach(courseBadges, (em, index)->
      courseBadge = new CourseBadgePrototype(em)
      $scope.courseBadges[em.id] = courseBadge
    )

  MetricBadgePrototype = (metric, courseBadge)->
    this.metric = metric
    this.courseBadge = courseBadge
  MetricBadgePrototype.prototype =
    create: ()->
      self = this
      Restangular.all('metricBadges').post(this.params())
        .then (response)->
          metricBadge = response.metricBadge
          self.id = metricBadge.id
    delete: (index)->
      self = this
      if this.isSaved()
        if confirm("Are you sure you want to delete this tier?")
          $http.delete("/tiers/#{self.id}").success(
            (data,status)->
              self.removeFromMetric(index)
              return true
          )
          .error((err)->
            alert("delete failed!")
            return false
          )
      else
        self.removeFromMetric(index)

    params: ()->
      metric_id: this.metric_id,
      id: this.id,
      name: this.name,
      description: this.description,
      point_total: this.point_total,
      icon: this.icon,
      multiple: this.multiple

    removeFromMetric: (index)->
      this.metric.badges.splice(index,1)

  TierBadgePrototype = (tier, courseBadge, attrs={})->
    this.tier = tier
    this.badge = courseBadge
    this.id = attrs.id
    this.name = attrs.name
    this.description = attrs.description
    this.point_total = attrs.point_total
    this.icon = attrs.icon
    this.multiple = attrs.multiple
  TierBadgePrototype.prototype =
    create: ()->
      self = this
      Restangular.all('tierBadges').post(this.params())
        .then (response)->
          tierBadge = response.tierBadge
          self.id = tierBadge.id
    delete: (index)->
      self = this
      if this.isSaved()
        if confirm("Are you sure you want to delete this tier?")
          $http.delete("/tiers/#{self.id}").success(
            (data,status)->
              self.removeFromTier(index)
              return true
          )
          .error((err)->
            alert("delete failed!")
            return false
          )
      else
        self.removeFromTier(index)
    params: ()->
      tier_id: this.tier_id,
      id: attrs.id,
      name: attrs.name,
      description: attrs.description,
      point_total: attrs.point_total,
      icon: attrs.icon,
      multiple: attrs.multiple

    removeFromTier: (index)->
      this.tier.badges.splice(index,1)




  # Metrics Section
  MetricPrototype = (attrs={})->
    this.tiers = []
    this.badges = {}
    this.availableBadges = angular.copy($scope.courseBadges)
    this.availableBadgesArray = $scope.courseBadgesArray
    this.selectedBadge = ""
    this.id = if attrs.id then attrs.id else null
    this.fullCreditTier = null
    this.addTiers(attrs["tiers"]) if attrs["tiers"] #add tiers if passed on init
    this.addBadges(attrs["badges"]) if attrs["badges"] #add badges if passed on init
    this.name = if attrs.name then attrs.name else ""
    this.rubricId = if attrs.rubric_id then attrs.rubric_id else $scope.rubricId
    if this.id
      this.max_points = if attrs.max_points then attrs.max_points else 0
    else
      this.max_points = if attrs.max_points then attrs.max_points else null

    this.description = if attrs.description then attrs.description else ""
    this.hasChanges = false
  MetricPrototype.prototype =
    # Tiers
    alert: ()->
      alert("snakes!")
    addTier: (attrs={})->
      self = this
      newTier = new TierPrototype(self, attrs)
      this.tiers.splice(-1, 0, newTier)
    addTiers: (tiers)->
      self = this
      angular.forEach(tiers, (tier,index)->
        self.loadTier(tier)
      )
    loadTier: (attrs={})->
      self = this
      newTier = new TierPrototype(self, attrs)
      this.tiers.push newTier
     
    # Badges
    addBadge: (attrs={})->
      self = this
      newBadge = new MetricBadgePrototype(self, attrs)
      this.badges.splice(-1, 0, newBadge)
    addBadges: (tiers)->
      self = this
      angular.forEach(tiers, (tier,index)->
        self.loadBadge(tier)
      )
    selectBadge: ()->
      self = this
      alert(self.selectedBadge.id)
      newBadge = new MetricBadgePrototype(self, self.selectedBadge)
      self.badges[self.selectedBadge.id] = newBadge
      delete self.availableBadges[self.selectedBadge.id]
      self.selectedBadge = ""
    badgeIds: ()->
      # distill ids for all badges
      self = this
      badgeIds = []
      angular.forEach(self.badges, (badge, index)->
        badgeIds.push(badge.id)
      )
      badgeIds

    isNew: ()->
      this.id is null
    isSaved: ()->
      this.id != null
    change: ()->
      self = this
      if this.fullCreditTier
        this.updateFullCreditTier()
      if this.isSaved()
        self.hasChanges = true
    updateFullCreditTier: ()->
      this.tiers[0].points = this.max_points
    resetChanges: ()->
      this.hasChanges = false
    resourceUrl: ()->
      "/metrics/#{self.id}"
    order: ()->
      jQuery.inArray(this, $scope.metrics)
    params: ()->
      self = this
      {
        name: self.name,
        max_points: self.max_points,
        order: self.order(),
        description: self.description,
        rubric_id: self.rubricId
      }
    index: ()->
      this.order()
    destroy: ()->

    remove:(index)->
      $scope.metrics.splice(index,1)
    create: ()->
      self = this
      Restangular.all('metrics').post(this.params())
        .then (response)->
          metric = response.existing_metric
          self.id = metric.id
          $scope.countSavedMetric()
          self.addTiers(metric.tiers)

    modify: (form)->
      if form.$valid
        if this.isNew()
          this.create()
        else
          this.update()

    update: ()->
      self = this
      if this.hasChanges
        Restangular.one('metrics', self.id).customPUT(self.params())
          .then(
            ()-> , #success
            ()-> # failure
          )
          self.resetChanges()

    delete: (index)->
      self = this
      if this.isSaved()
        if confirm("Are you sure you want to delete this metric? Deleting this metric will delete its tiers as well.")
          $http.delete("/metrics/#{self.id}").success(
            (data,status)->
              self.remove(index)
          )
          .error((err)->
            alert("delete failed!")
          )
      else
        self.remove(index)

  $scope.addMetrics = (existingMetrics)->
    angular.forEach(existingMetrics, (em, index)->
      emProto = new MetricPrototype(em)
      $scope.countSavedMetric() # indicate saved metric present
      $scope.metrics.push emProto
    )

  $scope.newMetric = ()->
    $scope.metrics.push new(MetricPrototype)

  $scope.getNewMetric = ()->
    $scope.newerMetric = Restangular.one('metrics', 'new.json').getList().then ()->

  $scope.viewMetrics = ()->
    if $scope.metrics.length > 0
      $scope.displayMetrics = []
      angular.forEach($scope.metrics, (value, key)->
        $scope.displayMetrics.push(value.name)
      )
      $scope.displayMetrics

  $scope.existingMetrics = []

  TierPrototype = (metric, attrs={})->
    this.id = attrs.id or null
    this.metric = metric
    this.badges = []
    this.availableBadges = $scope.courseBadgesById
    this.selectedBadge = ""
    this.addBadges(attrs["badges"]) if attrs["badges"] #add badges if passed on init
    this.metric_id = metric.id
    this.name = attrs.name or ""
    this.points = attrs.points
    this.fullCredit = attrs.full_credit or false
    this.noCredit = attrs.no_credit or false
    this.durable = attrs.durable or false
    this.description = attrs.description or ""
    this.resetChanges()
  TierPrototype.prototype =
    isNew: ()->
      this.id is null
    isSaved: ()->
      this.id > 0
    change: ()->
      self = this
      if this.isSaved()
        self.hasChanges = true
    alert: ()->
      alert("snakes!")

    # Badges
    addBadge: (attrs={})->
      self = this
      newBadge = new TierBadgePrototype(self, attrs)
      this.badges.splice(-1, 0, newBadge)
    addBadges: (tiers)->
      self = this
      angular.forEach(badges, (badge,index)->
        self.loadBadge(badge)
      )
    selectBadge: (attrs={})->
      self = this
      newBadge = new TierBadgePrototype(self, attrs)
      this.badges.push newBadge

    resetChanges: ()->
      this.hasChanges = false
    params: ()->
      metric_id: this.metric_id,
      name: this.name,
      points: this.points,
      description: this.description
    create: ()->
      self = this
      Restangular.all('tiers').post(self.params())
        .then(
          (response)-> #success
            self.id = response.id
          (response)-> #error
        )

    modify: (form)->
      if form.$valid
        if this.isNew()
          this.create()
        else
          this.update()

    update: ()->
      if this.hasChanges
        self = this
        Restangular.one('tiers', self.id).customPUT(self.params())
          .then(
            ()-> #success
            ()-> #failure
          )
          self.resetChanges()

     metricName: ()->
       alert this.metric.name

     delete: (index)->
      self = this
      if this.isSaved()
        if confirm("Are you sure you want to delete this tier?")
          $http.delete("/tiers/#{self.id}").success(
            (data,status)->
              self.removeFromMetric(index)
              return true
          )
          .error((err)->
            alert("delete failed!")
            return false
          )
      else
        self.removeFromMetric(index)
     removeFromMetric: (index)->
       this.metric.tiers.splice(index,1)

  # declare a sortableEle variable for the sortable function
  sortableEle = undefined

  # action when a sortable drag begins
  $scope.dragStart = (e, ui) ->
    ui.item.data "start", ui.item.index()
    return

  # action when a sortable drag completes
  $scope.dragEnd = (e, ui) ->
    start = ui.item.data("start")
    end = ui.item.index()
    $scope.metrics.splice end, 0, $scope.metrics.splice(start, 1)[0]
    $scope.$apply()
    $scope.updateMetricOrder()
    return

  # send the metric order to the server with ids
  $scope.updateMetricOrder = ()->
    if $scope.savedMetricCount > 0
      $http.put("/metrics/update_order", metric_order: $scope.orderedMetrics()).success(
      )
      .error(
      )

  # distill key/value pairs for metric ids and relative order
  $scope.orderedMetrics = ()->
    metrics = {}
    angular.forEach($scope.metrics, (value, index)->
      metrics[value.id] = {order: index} if value.id != null
    )
    metrics

  sortableEle = $("#metric-box").sortable(
    start: $scope.dragStart
    update: $scope.dragEnd
  )
  return
