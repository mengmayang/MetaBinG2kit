angular.module('app',['app.controllers']);
angular.module('app.controllers', ['PlotModule']);
(function(){
	angular
	.module('PlotModule',[])
	.controller('PlotCtrl',PlotCtrl);

	PlotCtrl.$inject=['$scope'];
	function PlotCtrl($scope){
		$scope.PlotFun=PlotFun;
		$scope.selectType=selectType;
		$scope.selectLevel=selectLevel;
		$scope.type=0;
		$scope.typeName="Pie";
		$scope.barlevel="phylum";
		$scope.content=s;

		EchartPlotPie();

		function PlotFun(){
			var t=$scope.type;
			$("#main").empty(); 
			if(t==0){
				EchartPlotPie();
			}
			else if(t==1){
				EchartPlotBar($scope.barlevel);
			}else if(t==2){
				EchartPlotStack($scope.barlevel);
			}
		}

		function selectType(t){
			$scope.type=t;
			if(t==0){
				$scope.typeName="Pie";
			}else if(t==1){
				$scope.typeName="Bar";
			}else if(t==2){
				$scope.typeName="Stack";
			}
		}

		function selectLevel(barlevel){
			$scope.barlevel=barlevel;
		}

		function EchartPlotStack(level){
			if(!$scope.content){
				alert("please input the stats content");
			}else{
				var level=level;
				var speciesArr=$scope.content.split("=M=");
				var speciesNum=speciesArr.length;
				var header=speciesArr[0].split("\t");
				var headerNum=header.length;
				var message="";
				var samples=[];
				var tax=["phylum","class","order","family","genus","species"];
				for(i=1;i<speciesNum;i++){
					var colArr=speciesArr[i].split("\t");
					if(colArr.length!=headerNum){
						message="Please check the format!";
						break;
					}
				}
				if(message){
					alert(message);
				}else{
					for(var i=1;i<speciesNum;i++){
						var colArr=speciesArr[i].split("\t");
						var taxArr=colArr[0].split(";");

						for(var j=1;j<headerNum;j++){
							for(var p=0;p<tax.length;p++){
								var sampleEle={};
								sampleEle.index=j;
								sampleEle.name=header[j];
								sampleEle.level=tax[p];
								sampleEle.taxname=taxArr[0];
								for(var q=1;q<(p+1);q++){
									sampleEle.taxname=sampleEle.taxname+"\_"+taxArr[q];
								}
								var tmpArr=colArr[j].split("\_");
								sampleEle.count=tmpArr[0];
								sampleEle.percent=tmpArr[1];
								samples.push(sampleEle);
							}	
						}
					}
					
					var themeColor=['#ff7f50', '#87cefa', '#da70d6', '#32cd32', '#6495ed', '#ff69b4', '#ba55d3', '#cd5c5c', '#ffa500', '#40e0d0','#1e90ff', '#ff6347', '#7b68ee', '#00fa9a', '#ffd700', '#6b8e23', '#ff00ff', '#3cb371', '#b8860b', '#30e0e0' ];

					var height=500;
					var width=800;

					var newDiv=document.createElement("div");
					newDiv.style.height=height+'px';
					newDiv.style.width=width+'px';
					var id1="newDiv";
					newDiv.id=id1;					
					document.getElementById("main").appendChild(newDiv);

					var headerIndexArr=[];
					for(var i=1;i<headerNum;i++){
						headerIndexArr.push(header[i]);// The number of samples
					}

					var taxNameArr=[];
					
					for(var i=0;i<samples.length;i++){
						if(samples[i].level==level){
							taxNameArr.push(samples[i].taxname);
						}
					}

					var taxNameUniq=taxNameArr.unique().sort();
					var seriesArr=[];

					for(var i2=0;i2<headerIndexArr.length;i2++){
						var serieobj={};
						serieobj.name=headerIndexArr[i2];
						serieobj.type='bar';
						var i1=i2+1;
						serieobj.data=getTaxInfo(level,i1);
						seriesArr.push(serieobj);
					}
					var i_sort;
					var data_sum=[];
					var data_sum_index=[];
					for(var n=0;n<taxNameUniq.length;n++){
						data_sum_index[n]=n;
					}
					var j;
					for(i_sort=0;i_sort<taxNameUniq.length;i_sort++){
						var s=0;
						for(j=0;j<seriesArr.length;j++){
							s=s+parseFloat(seriesArr[j].data[i_sort]);
						}
						data_sum.push(s);
					}
					var i_sum;
					var j_sum;
					var tmp;
					for(i_sum=0;i_sum<data_sum.length;i_sum++){
						for(j_sum=(i_sum+1);j_sum<data_sum.length;j_sum++){
							if(data_sum[j_sum]>data_sum[i_sum]){
								tmp=data_sum[i_sum];
								data_sum[i_sum]=data_sum[j_sum];
								data_sum[j_sum]=tmp;
								tmp=data_sum_index[i_sum];
								data_sum_index[i_sum]=data_sum_index[j_sum];
								data_sum_index[j_sum]=tmp;
							}
						}
					}

					var i;
					var taxNameUniq_new=[];
					for(i=0;i<data_sum_index.length;i++){
						taxNameUniq_new.push(taxNameUniq[data_sum_index[i]]);
					}

					var j;
					var j1;
					var seriesArr_new=[];

					for(j=0;j<taxNameUniq_new.length;j++){
						var serieobj={};
						var data=[];
						serieobj.name=taxNameUniq_new[j];
						serieobj.type='line';
						serieobj.stack='总量';
						var areaStyle_o={};
						var item_n={};
						item_n.color=themeColor[j];
						areaStyle_o.normal=item_n;
						serieobj.areaStyle=areaStyle_o;
						for(j1=0;j1<headerIndexArr.length;j1++){
							data.push(seriesArr[j1].data[data_sum_index[j]]);
						}
						serieobj.data=data;
						seriesArr_new.push(serieobj);
					}


					option = {
					    title: {
					        text: ''
					    },
					    tooltip : {
					        trigger: 'axis',
					        axisPointer: {
					            type: 'cross',
					            label: {
					                backgroundColor: '#6a7985'
					            }
					        }
					    },
					    legend: {
        					type: 'scroll',
					        // orient: 'vertical',
					        right:0,
					        top:'15%',
					        // bottom:'10%',
        					data: taxNameUniq_new
    					},
					    toolbox: {
					        feature: {
					            saveAsImage: {}
					        }
					    },
					    grid: {
					        left: '3%',
					        right: '10%',
					        bottom: '3%',
					        containLabel: true
					    },
					    xAxis : [
					        {
					            type : 'category',
					            boundaryGap : false,
					            data : headerIndexArr
					        }
					    ],
					    yAxis : [
					        {
					            type : 'value'
					        }
					    ],
					    series : seriesArr_new
					};

					var myChart1 = echarts.init(document.getElementById(id1));
					myChart1.setOption(option);


					function getTaxInfo(level,index){
						var phylum=[];
						phylumUniq=[];
						var phylumP=[];
						for(i=0;i<samples.length;i++){
							if(samples[i].index==index && samples[i].level==level){
								var obj={};
								obj.name=samples[i].taxname;
								phylumUniq.push(obj.name);
								obj.value=samples[i].count;
								obj.percent=samples[i].percent;
								phylum.push(obj);
							}
						}
						phylumUniq=phylumUniq.unique().sort();

						for(i=0;i<phylumUniq.length;i++){
							var obj={};
							var tmpArr=phylumUniq[i].split("\_");
							obj.name=tmpArr[tmpArr.length-1];
							var value=0;
							var percent=0.0;
							for(j=0;j<phylum.length;j++){
								if(phylum[j].name==phylumUniq[i]){
									value=value+parseInt(phylum[j].value);
									percent=percent+parseFloat(phylum[j].percent);
								}
							}
							obj.value=value;
							obj.percent=percent;
							phylumP.push(obj);
						}
						var phylumData=[];
						for(i=0;i<phylumP.length;i++){
							phylumData.push(phylumP[i].percent);
						}
						return(phylumData);
					}

					
				}
				
				
			}
		}

		function EchartPlotBar(level){
			if(!$scope.content){
				alert("please input the stats content");
			}else{
				var level=level;
				var speciesArr=$scope.content.split("=M=");
				var speciesNum=speciesArr.length;
				var header=speciesArr[0].split("\t");
				var headerNum=header.length;
				var message="";
				var samples=[];
				var tax=["phylum","class","order","family","genus","species"];
				for(i=1;i<speciesNum;i++){
					var colArr=speciesArr[i].split("\t");
					if(colArr.length!=headerNum){
						message="Please check the format!";
						break;
					}
				}
				if(message){
					alert(message);
				}else{
					for(var i=1;i<speciesNum;i++){
						var colArr=speciesArr[i].split("\t");
						var taxArr=colArr[0].split(";");

						for(var j=1;j<headerNum;j++){
							for(var p=0;p<tax.length;p++){
								var sampleEle={};
								sampleEle.index=j;
								sampleEle.name=header[j];
								sampleEle.level=tax[p];
								sampleEle.taxname=taxArr[0];
								for(var q=1;q<(p+1);q++){
									sampleEle.taxname=sampleEle.taxname+"\_"+taxArr[q];
								}
								var tmpArr=colArr[j].split("\_");
								sampleEle.count=tmpArr[0];
								sampleEle.percent=tmpArr[1];
								samples.push(sampleEle);
							}	
						}
					}
					
					var themeColor=['#ff7f50', '#87cefa', '#da70d6', '#32cd32', '#6495ed', '#ff69b4', '#ba55d3', '#cd5c5c', '#ffa500', '#40e0d0','#1e90ff', '#ff6347', '#7b68ee', '#00fa9a', '#ffd700', '#6b8e23', '#ff00ff', '#3cb371', '#b8860b', '#30e0e0' ];

					var height=500;
					var width=700;

					var newDiv=document.createElement("div");
					newDiv.style.height=height+'px';
					newDiv.style.width=width+'px';
					var id1="newDiv";
					newDiv.id=id1;					
					document.getElementById("main").appendChild(newDiv);

					var headerIndexArr=[];
					for(var i=1;i<headerNum;i++){
						headerIndexArr.push(header[i]);// The number of samples
					}


					var taxNameArr=[];
					
					for(var i=0;i<samples.length;i++){
						if(samples[i].level==level){
							taxNameArr.push(samples[i].taxname);
						}
					}

					var taxNameUniq=taxNameArr.unique().sort();
					var seriesArr=[];

					for(var i2=0;i2<headerIndexArr.length;i2++){
						var serieobj={};
						serieobj.name=headerIndexArr[i2];
						serieobj.type='bar';
						var i1=i2+1;
						serieobj.data=getTaxInfo(level,i1);
						// var mp={};
						// mp.data=[
						// 	{type:'max',name:'max'},
						// 	{type:'main',name:'min'}
						// ];
						// serieobj.markPoint=mp;
						// var ml={};
						// ml.data=[
						// 	{type:'average',name:'mean'}
						// ];
						// serieobj.markLine=ml;
						seriesArr.push(serieobj);
					}
					//对n个样本取每个物种的平均数再排序
					var i_sort;
					var data_sum=[];
					var data_sum_index=[];
					for(var n=0;n<taxNameUniq.length;n++){
						data_sum_index[n]=n;
					}
					var j;
					for(i_sort=0;i_sort<taxNameUniq.length;i_sort++){
						var s=0;
						for(j=0;j<seriesArr.length;j++){
							s=s+parseInt(seriesArr[j].data[i_sort]);
						}
						data_sum.push(s);
					}
					var i_sum;
					var j_sum;
					var tmp;
					for(i_sum=0;i_sum<data_sum.length;i_sum++){
						for(j_sum=(i_sum+1);j_sum<data_sum.length;j_sum++){
							if(data_sum[j_sum]>data_sum[i_sum]){
								tmp=data_sum[i_sum];
								data_sum[i_sum]=data_sum[j_sum];
								data_sum[j_sum]=tmp;
								tmp=data_sum_index[i_sum];
								data_sum_index[i_sum]=data_sum_index[j_sum];
								data_sum_index[j_sum]=tmp;
							}
						}
					}

					var i;
					var taxNameUniq_new=[];
					for(i=0;i<data_sum_index.length;i++){
						taxNameUniq_new.push(taxNameUniq[data_sum_index[i]]);
					}

					var j;
					var j1;
					var seriesArr_new=[];
					for(j=0;j<headerIndexArr.length;j++){
						var data=[];
						var serieobj={};
						serieobj.name=headerIndexArr[j];
						serieobj.type='bar';
						for(j1=0;j1<seriesArr[j].data.length;j1++){
							data.push(seriesArr[j].data[data_sum_index[j1]]);
						}
						serieobj.data=data;
						seriesArr_new.push(serieobj);
					}

					option = {
						title:{
							text:'Bar',
							// subtext:header[i1+1],
							// left:'center',
						},
					    tooltip: {
					        // trigger: 'item',
					        // formatter: "{a} <br/>{b}: {c} ({d}%)"
					    	trigger:'axis'
					    },
					    legend:{
					    	data:headerIndexArr
					    },
					    toolbox:{
					    	show:true,
					    	feature:{
					    		dataView:{
					    			show:true,
					    			readOnly:false
					    		},
					    		restore:{show:true},
					    		saveAsImage: {show: true},
					    		magicType:{
					    			show:true,
					    			type:['line','bar','stack']
					    		}
					    	}
					    },
					    calculable : true,
					    xAxis:[
					    	{
					    		type:'category',
					    		data:taxNameUniq_new
					    	}
					    ],
					    yAxis:[
					    	{
					    		type:'value'
					    	}
					    ],
					    series: seriesArr_new
					};

					var myChart1 = echarts.init(document.getElementById(id1));
					myChart1.setOption(option);


					function getTaxInfo(level,index){
						var phylum=[];
						phylumUniq=[];
						var phylumP=[];
						for(i=0;i<samples.length;i++){
							if(samples[i].index==index && samples[i].level==level){
								var obj={};
								obj.name=samples[i].taxname;
								phylumUniq.push(obj.name);
								obj.value=samples[i].count;
								obj.percent=samples[i].percent;
								phylum.push(obj);
							}
						}
						phylumUniq=phylumUniq.unique().sort();

						for(i=0;i<phylumUniq.length;i++){
							var obj={};
							var tmpArr=phylumUniq[i].split("\_");
							obj.name=tmpArr[tmpArr.length-1];
							var value=0;
							var percent=0.0;
							for(j=0;j<phylum.length;j++){
								if(phylum[j].name==phylumUniq[i]){
									value=value+parseInt(phylum[j].value);
									percent=percent+parseFloat(phylum[j].percent);
								}
							}
							obj.value=value;
							obj.percent=percent;
							phylumP.push(obj);
						}
						var phylumData=[];
						for(i=0;i<phylumP.length;i++){
							phylumData.push(phylumP[i].value);
						}
						return(phylumData);
					}

					
				}
				
				
			}
		}

		function EchartPlotPie(){
			if(!$scope.content){
				alert("please input the stats content");
			}else{
				var speciesArr=$scope.content.split("=M=");
				var speciesNum=speciesArr.length;
				var header=speciesArr[0].split("\t");
				var headerNum=header.length;
				var message="";
				var samples=[];
				var tax=["phylum","class","order","family","genus","species"];
				for(i=1;i<speciesNum;i++){
					var colArr=speciesArr[i].split("\t");
					if(colArr.length!=headerNum){
						message="Please check the format!";
						break;						
					}
				}
				if(message){
					alert(message);
				}else{
					for(var i=1;i<speciesNum;i++){
						var colArr=speciesArr[i].split("\t");
						var taxArr=colArr[0].split(";");

						for(var j=1;j<headerNum;j++){
							for(var p=0;p<tax.length;p++){
								var sampleEle={};
								sampleEle.index=j;
								sampleEle.name=header[j];
								sampleEle.level=tax[p];
								sampleEle.taxname=taxArr[0];
								for(var q=1;q<(p+1);q++){
									sampleEle.taxname=sampleEle.taxname+"\_"+taxArr[q];
								}
								var tmpArr=colArr[j].split("\_");
								sampleEle.count=tmpArr[0];
								sampleEle.percent=tmpArr[1];
								samples.push(sampleEle);
							}	
						}
					}
					
					var themeColor=['#ff7f50', '#87cefa', '#da70d6', '#32cd32', '#6495ed', '#ff69b4', '#ba55d3', '#cd5c5c', '#ffa500', '#40e0d0','#1e90ff', '#ff6347', '#7b68ee', '#00fa9a', '#ffd700', '#6b8e23', '#ff00ff', '#3cb371', '#b8860b', '#30e0e0' ];

					var divID=[];
					var height=300;
					var width=300;
					if(headerNum>2){
						d=parseInt(300-20*headerNum);
						if(d<200){
							height=200;
							width=200;
						}else{
							height=d;
							width=d;
						}

					}
					for(var i=0;i<(headerNum-1);i++){
						var newDiv=document.createElement("div");
						newDiv.style.height=height+'px';
						newDiv.style.width=height+'px';
						newDiv.setAttribute("class","col-sm-2");
						var id="newDiv"+i;
						newDiv.id=id;
						divID.push(id);						
						document.getElementById("main").appendChild(newDiv);
					}

					var Phylumfirstcolor=[];
					var Classfistcolor=[];
					var Orderfirstcolor=[];
					var Familyfirstcolor=[];
					var Genusfirstcolor=[];
					var Speciesfirstcolor=[];
					for(var i1=0;i1<divID.length;i1++){
						var index=i1+1;
						if(index<=1){
							Phylumfirstcolor=getTaxInfo("phylum",1,index,Phylumfirstcolor).refcolor;
							Classfirstcolor=getTaxInfo("class",2,index,Classfistcolor).refcolor;
							Orderfirstcolor=getTaxInfo("order",3,index,Orderfirstcolor).refcolor;
							Familyfirstcolor=getTaxInfo("family",4,index,Familyfirstcolor).refcolor;
							Genusfirstcolor=getTaxInfo("genus",5,index,Genusfirstcolor).refcolor;
							Speciesfirstcolor=getTaxInfo("species",6,index,Speciesfirstcolor).refcolor;
						}
						var phylumData=getTaxInfo("phylum",1,index,Phylumfirstcolor).outData;
						var classData=getTaxInfo("class",2,index,Classfirstcolor).outData;
						var orderData=getTaxInfo("order",3,index,Orderfirstcolor).outData;
						var familyData=getTaxInfo("family",4,index,Familyfirstcolor).outData;
						var genusData=getTaxInfo("genus",5,index,Genusfirstcolor).outData;
						var speciesData=getTaxInfo("species",6,index,Speciesfirstcolor).outData;

						option = {
							title:{
								text:(i1+1),
								// subtext:header[i1+1],
								left:'center',
							},
						    tooltip: {
						        trigger: 'item',
						        formatter: "{a} <br/>{b}: {c} ({d}%)"
						    },
						    toolbox: {
						        show: true,
						        feature: {
						            dataView: {readOnly: false},
						            restore: {},
						            saveAsImage: {}
						        }
						    },
						    series: [
						        {
						            name:'phylum',
						            type:'pie',
						            selectedMode: 'single',
						            radius: [0, '30%'],

						            label: {
						                normal: {
						                    show:false
						                }
						            },
						            data:phylumData
						        },
						        {
						            name:'class',
						            type:'pie',
						            radius: ['35%', '45%'],
						            label: {
						                normal: {
						                    // position: 'inner'
						                    show:false
						                }
						            },
						            data:classData
						        },
						        {
						            name:'order',
						            type:'pie',
						            radius: ['50%', '60%'],
						            label: {
						                normal: {
						                    show:false
						                }
						            },
						            data:orderData
						        },
						        {
						            name:'family',
						            type:'pie',
						            selectedMode: 'single',
						            radius: ['65%', '70%'],

						            label: {
						                normal: {
						                    show:false
						                }
						            },
						            data:familyData
						        },
						        {
						            name:'genus',
						            type:'pie',
						            selectedMode: 'single',
						            radius: ["75%", '80%'],

						            label: {
						                normal: {
						                    show:false
						                }
						            },
						            data:genusData
						        },
						        // {
						        //     name:'species',
						        //     type:'pie',
						        //     selectedMode: 'single',
						        //     radius: ["85%", '90%'],

						        //     label: {
						        //         normal: {
						        //             show:false
						        //         }
						        //     },
						        //     data:speciesData
						        // }
						    ]
						};
						var id=divID[i1];
						var myChart = echarts.init(document.getElementById(divID[i1]));
						myChart.setOption(option);

					}


					function getTaxInfo(level,l,index,firstcolor){
						var phylum=[];
						phylumUniq=[];
						var phylumP=[];
						var refcolor=[];
						if(index>1){
							refcolor=firstcolor;
						}
						for(i=0;i<samples.length;i++){
							if(samples[i].index==index && samples[i].level==level){
								var obj={};
								obj.name=samples[i].taxname;
								phylumUniq.push(obj.name);
								obj.value=samples[i].count;
								obj.percent=samples[i].percent;
								phylum.push(obj);
							}
						}

						phylumUniq=phylumUniq.unique().sort();

						var cumPercentage=0;
						for(i=0;i<phylumUniq.length;i++){
							var obj={};
							var tmpArr=phylumUniq[i].split("\_");
							obj.name=tmpArr[tmpArr.length-1];
							var value=0;
							var percent=0.0;
							for(j=0;j<phylum.length;j++){
								if(phylum[j].name==phylumUniq[i]){
									value=value+parseInt(phylum[j].value);
									percent=percent+parseFloat(phylum[j].percent);
								}
							}
							cumPercentage=cumPercentage+percent;
							obj.value=value;
							obj.percent=percent;
							var h=2*Math.PI*cumPercentage;
							var s=Math.max(0.2,1-l*0.12);
							var v=1;
							var col=getHSVColor(h,s,v);
							if(index>1){
								obj.color=refcolor[i];
							}else{
								//obj.color=col;
								obj.color=themeColor[i]//需要修改颜色
								//refcolor.push(col);
								refcolor.push(obj.color);
							}
							phylumP.push(obj);
						}
						var phylumData=[];
						for(i=0;i<phylumP.length;i++){
							var Ele={};
							Ele.name=phylumP[i].name;
							Ele.value=phylumP[i].value;
							var item_n={};
							item_n.color=phylumP[i].color;
							var item={};
							item.normal=item_n;
							Ele.itemStyle=item;
							phylumData.push(Ele);
						}
						var out={};
						out.outData=phylumData;
						out.refcolor=refcolor;
						return(out);
					}
					
				}
				
				
			}	
		}

		function colorToRGB(){
			var sColor = "#34538b";
			var reg = /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/;
			if(sColor && reg.test(sColor)){
				if(sColor.length === 4){
					var sColorNew = "#";
					for(var i=1; i<4; i+=1){
						sColorNew += sColor.slice(i,i+1).concat(sColor.slice(i,i+1));	
					}
					sColor = sColorNew;
				}
				var sColorChange = [];
				for(var i=1; i<7; i+=2){
					sColorChange.push(parseInt("0x"+sColor.slice(i,i+2)));	
				}
				return "RGB(" + sColorChange.join(",") + ")";
			}else{
				return sColor;	
			}
		}

		//HSV 转化成 RGB
    	/* h, s, v (0 ~ 1) */
	    function getHSVColor(h, s, v) {
	        var r, g, b, i, f, p, q, t;
	        
	        if (h && s === undefined && v === undefined) {
	            s = h.s, v = h.v, h = h.h;
	        }
	        i = Math.floor(h * 6);
	        f = h * 6 - i;
	        p = v * (1 - s);
	        q = v * (1 - f * s);
	        t = v * (1 - (1 - f) * s);
	        switch (i % 6) {
	            case 0: r = v, g = t, b = p; break;
	            case 1: r = q, g = v, b = p; break;
	            case 2: r = p, g = v, b = t; break;
	            case 3: r = p, g = q, b = v; break;
	            case 4: r = t, g = p, b = v; break;
	            case 5: r = v, g = p, b = q; break;
	        }

	        var rgb='#'+toHex(r*255)+toHex(g*255)+toHex(b*255);
	        return rgb;
	    }
		
		function toHex(num){//将一个数字转化成16进制字符串形式
			if( typeof num !== 'undefined' ){
		        return Math.floor(Number(num)).toString( 16 );
		    }
		}

		Array.prototype.unique = function(){
			this.sort(); 
			var res = [this[0]];
			for(var i = 1; i < this.length; i++){
				if(this[i] !== res[res.length - 1]){
		   			res.push(this[i]);
		  		}
		 	}
		 	return res;
		}
		
	}
})();


