import { LightningElement, api, track, wire } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';
import chartjs from '@salesforce/resourceUrl/chartjs';
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getProjectActualsWrapper from '@salesforce/apex/PerformanceIndicatorLWCController.getProjectActualsVsForecasts';

export default class EmployeeProjectActualsVsForecastChart extends LightningElement {

    @api recordId;

    chartConfiguration;
 
    @wire(getProjectActualsWrapper, { contactRecordId: '$recordId'})
    getWrapper({error, data}) {
        if (error) {
            this.error = error;
            this.chartConfiguration = undefined;
            console.log('ERROR: ', error);
        } else if (data) {
            let currentWeeklyTarget;
            let weekEndDateLabels = [];
            let hoursAboveForecastList = [];
            let forecastedHoursList = [];
            const projectMap = new Map();
            console.log('GOOD DATA: ', data);
            data.forEach(wrapper => {
                for(let key in wrapper.projectToWrapperMap){
                    let projectHoursMap = [];
                    projectMap.set(key, projectHoursMap);
                };

                forecastedHoursList.push(wrapper.forecastedHours);
                hoursAboveForecastList.push(wrapper.hoursAboveForecast);

                let splitDate = wrapper.weekEndDate.split('-');
                let weekEndDateString = splitDate[1] + '/' + splitDate[2]  + '/' + splitDate[0];
                weekEndDateLabels.push(weekEndDateString);
            });
            let projectMapKeys = projectMap.keys();

            data.forEach(wrapper => {
            //This loops through each Wrapper Object, which is a record for each Week End Date
                const loopProjectMap = new Map();
                for(let key in wrapper.projectToWrapperMap){
                    loopProjectMap.set(key, wrapper.projectToWrapperMap[key].totalProjectHours);
                }

                for (const [projName, value] of projectMap.entries()) {
                    //Loops through ALL Projects in entire data
                    //So if it occurs in an iteration add the totalProjectHours, if else then add 0 since that project has 0 hours for that week
                    if(loopProjectMap.has(projName)){
                        let projectHourList = [];
                        projectHourList = projectMap.get(projName);
                        projectHourList.push(loopProjectMap.get(projName));
                        projectMap.set(projName, projectHourList);
                    }else{
                        let projectHourList = [];
                        projectHourList = projectMap.get(projName);
                        projectHourList.push(0);
                        projectMap.set(projName, projectHourList);
                    }
                }
            });           

            let datasetList = [];

            let hoursAboveForecastDataset = {
                type: 'line',
                fill: false,
                label: 'Hours Above Forecast',
                order: 0,
                data: hoursAboveForecastList,
                backgroundColor: [
                    'rgba(255, 99, 132, 0.2)'
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)'
                ],
                pointBackgroundColor: 'rgba(255, 99, 132, 0.2)',
                pointBorderColor: 'rgba(255, 99, 132, 1)'
            }

            let totalForecastedHours = {
                type: 'line',
                fill: false,
                label: 'Total Forecasted Hours',
                order: 0,
                data: forecastedHoursList,
                backgroundColor: [
                    '#80aaff'
                ],
                borderColor: [
                    'blue'
                ],
                pointBackgroundColor: '#80aaff',
                pointBorderColor: 'blue'
            }

            datasetList.push(hoursAboveForecastDataset);
            datasetList.push(totalForecastedHours);

            for (const [key, value] of projectMap.entries()) {

                //Generate Color from the name so that the color is the same for each project across all columns, and so that colors are generated dynamically
                let hash = 0;
                for (let i = 0; i < key.length; i++) {
                hash = key.charCodeAt(i) + ((hash << 5) - hash);
                }
                let color = '#';
                for (let i = 0; i < 3; i++) {
                    let value = (hash >> (i * 8)) & 0xFF;
                    color += ('00' + value.toString(16)).substr(-2);
                }
                //Put the color in a list so that each bar has a color, the first in the list relates to the first value in the data set
                //So if only one color given, then only the first datapoint (bar) would be colored
                let datasetColorList = [];
                for(let j = 0; j<=value.length; j++){
                    datasetColorList.push(color);
                }

                let dataset = {
                    label: key, //Label is the Project Name
                    backgroundColor: datasetColorList, //Color for each bar in the chart for this projects hours
                    stack: 'stack 1', //Stack all
                    order: 1, //Attempt to order the bar graph behind the line graph
                    data: value //Add the hours to the value of the dataset
                };
                datasetList.push(dataset);
                
            }  
            console.log('projectMap 2: ', projectMap );
            console.log('datasetList: ', datasetList);
 
            this.chartConfiguration = {
                type: 'bar',
                data: 
                {
                    datasets: datasetList,
                    labels: weekEndDateLabels,
                },
                options: {
                    title: {
                        display: true,
                        text: 'Project Actuals vs Forecasts'
                    },
                    legend: {
                        display: false,
                        //maxHeight: 25,
                    },
                    scales: {
                        yAxes: [{
                            ticks: {
                                beginAtZero: true,
                                //min: 0,
                            },
                            scaleLabel: {
                                display: true,
                                labelString: 'Total Hours'
                              }
                        }],
                        xAxes: [{
                            ticks: {
                                //min: 0,
                            },
                            scaleLabel: {
                                display: true,
                                labelString: 'Week End Date'
                              }
                        }]
                      },
                      tooltips: {
                        /*enabled: true,
                        mode: 'single',
                        callbacks: {
                            label: function(tooltipItems, data) { 
                                return tooltipItems.yLabel + ' : ' + tooltipItems.xLabel + " HERE!";
                            }
                        }*/
                    },
                },
            };
            console.log('data => ', data);
            this.error = undefined;
        }else{
            console.log('What???');
            refreshApex(this.getWrapper);
        }
    }
}