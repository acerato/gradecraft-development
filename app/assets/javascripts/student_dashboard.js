$(document).ready(function() {

    function createOptions () {
    return {
    chart: {
      type: 'bar',
      backgroundColor: null
    },
    
    colors: [
     '#00274F',
     '#215089',
     '#2E70BE',
     '#B9D6F2',
     '#8ED0FF',
     '#490454',
     '#8F27A1',
     '#9FE88D',
     '#6DD677',
     '#25B256',
     '#D1495B',
     '#EDAE49',
     '#FFCF06'
  ],

    credits: {
      enabled: false
    },
    xAxis: {
      gridLineWidth: 0,
      lineColor: '#000',
      title: {
        text: ' '
      },
      labels: {
        style: {
          color: "#000"
        }
      }
    },
    yAxis: {
      gridLineWidth: 1,
      lineColor: '#000',
      min: 0,
      title: {
        text: ' '
      },
      labels: {
        style: {
          color: "#000"
        }
      }
    },
    tooltip: {
      formatter: function() {
        return '<b>'+ this.series.name +'</b><br/>'+
        this.y + ' points';
      }
    },
    plotOptions: {
      series: {
        stacking: 'normal',
        borderWidth: 0,
        pointWidth: 40,
        events: {
          legendItemClick: function () {
              return false;
          }
        }
      }
    },
    legend: {
      enabled: false
    }
  };
  }

    var chart, categories, assignment_type_name, scores, grade_levels;
    if ($('#userBarTotal').length) {
      var data = JSON.parse($('#data-predictor').attr('data-predictor'));

      var options = createOptions()
      options.chart.renderTo = 'userBarTotal';
      options.title = { text: '', margin: 0 };
      options.xAxis.categories = { text: ' ' };
      options.yAxis.max = data.course_total;
      options.yAxis.plotBands = data.grade_levels;
      options.series = data.scores;
      chart = new Highcharts.Chart(options);
    };
});

// Filter my planner items in "due this week" module
$('#my-planner').click(function() {
  $('#course-planner, #my-planner').toggleClass("selected");
  $('.my-planner-list').show();
  $('.course-planner-list').hide();
});

$('#course-planner').click(function() {
  $('#course-planner, #my-planner').toggleClass("selected");
  $('.course-planner-list').show();
  $('.my-planner-list').hide();
});

//Find event with closest date
if($("#dashboard-timeline").length) {
  $.ajax({
    type: 'GET',
    url: '/timeline_events',
    dataType: 'json',
    contentType: 'application/json',
    success: function (json) {
      setInitialEventSlide(json);
    }
 });
}

function setInitialEventSlide(eventJson){
  var events = eventJson.timeline.date;
  var todaysDate = new Date();
  var startIndex = null;

  for (var i = 0; i < events.length; i++) {
    var eventEndDate = new Date(events[i].endDate);
    if (eventEndDate >= todaysDate) {
      startIndex = i;
      break;
    }
  }

  if (startIndex === null) {
    $('.slide-container').append('<div class="event-slide last-slide"><p>This class has no upcoming events!</p></div>');
    startIndex = events.length;
  }

  $('#events-loading-spinner').hide();
  initSlickSlider(startIndex);
}

// Initialize slick slider for course events
function initSlickSlider(startIndex) {
  $('.slide-container').slick({
    prevArrow: '<a class="fa fa-chevron-left previous slider-direction-button"></a>',
    nextArrow: '<a class="fa fa-chevron-right next slider-direction-button"></a>',
    initialSlide: startIndex,
    adaptiveHeight: true, 
    infinite: false
  });
}
