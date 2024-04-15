public  class RepliconBillingRateResponse {

    public List<d> d {get;set;} 

	public RepliconBillingRateResponse(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'd') {
						d = arrayOfd(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'JSON2Apex consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class d {
		public BillingRate billingRate {get;set;} 
		public EffectiveBillingRate effectiveBillingRate {get;set;}
        public Boolean isAvailableForAssignmentToTeamMembers {get;set;}

		public d(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'billingRate') {
							billingRate = new BillingRate(parser);
						} else if (text == 'effectiveBillingRate') {
							effectiveBillingRate = new EffectiveBillingRate(parser);
						} else if (text == 'isAvailableForAssignmentToTeamMembers') {
							isAvailableForAssignmentToTeamMembers = parser.getBooleanValue();
						} else {
							System.debug(LoggingLevel.WARN, 'd consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}

    public class BillingRate {
        public String displayText {get;set;}
        public String name {get;set;} 
        public String uri {get;set;} 

        public BillingRate(JSONParser parser){
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'displayText') {
							displayText = parser.getText();
						} else if (text == 'name') {
							name = parser.getText();
                        } else if (text == 'uri') {
							uri = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Billing Rate consuming unrecognized property: ' + text);
							consumeObject(parser);
						}
					}
				}
			}
        }
    }

    public class EffectiveBillingRate {
        public AsOfDate asOfDate {get;set;}
        public String billingRateScheduleEntryUri {get;set;} 
        public Date effectiveDate {get;set;} 
        public String frequency {get;set;} 
        public Value value {get;set;} 

        public EffectiveBillingRate(JSONParser parser){
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'asOfDate') {
							asOfDate = new AsOfDate(parser);
						} else if (text == 'billingRateScheduleEntryUri') {
							//Do nothing
                        } else if (text == 'effectiveDate') {
							//Do nothing
						} else if (text == 'endDate') {
							//Do nothing
						} else if (text == 'frequency') {
							//Do nothing
						} else if (text == 'value') {
							value = new Value(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Effective Billing Rate consuming unrecognized property: ' + text);
							consumeObject(parser);
						}
					}
				}
			}
        }
    }

    public class AsOfDate {
        public Integer day {get;set;}
        public Integer month {get;set;}
        public Integer year {get;set;}

        public AsOfDate(JSONParser parser){
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'day') {
							day = parser.getIntegerValue();
						} else if (text == 'month') {
							month = parser.getIntegerValue();
                        } else if (text == 'year'){
                            year = parser.getIntegerValue();
                        }else {
							System.debug(LoggingLevel.WARN, 'Value consuming unrecognized property: ' + text);
							consumeObject(parser);
						}
					}
				}
			}
        }
    }

    public class Value {
        public Decimal amount {get;set;}
        public RateCurrency rateCurrency {get;set;}

        public Value(JSONParser parser){
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'amount') {
							amount = parser.getDecimalValue();
						} else if (text == 'currency') {
							rateCurrency = new RateCurrency(parser);
                        } else {
							System.debug(LoggingLevel.WARN, 'Value consuming unrecognized property: ' + text);
							consumeObject(parser);
						}
					}
				}
			}
        }
    }

    public class RateCurrency {
        public String displayText {get;set;}
        public String name {get;set;}
        public String symbol {get;set;}
        public String uri {get;set;}

        public RateCurrency(JSONParser parser){
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'displayText') {
							displayText = parser.getText();
						} else if (text == 'name') {
							name = parser.getText();
                        } else if (text == 'symbol') {
							symbol = parser.getText();
                        } else if (text == 'uri') {
							uri = parser.getText();
                        } else {
							System.debug(LoggingLevel.WARN, 'Rate Currency consuming unrecognized property: ' + text);
							consumeObject(parser);
						}
					}
				}
			}
        }
    }

    public static RepliconBillingRateResponse parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new RepliconBillingRateResponse(parser);
	}

    private static List<d> arrayOfd(System.JSONParser p) {
        List<d> res = new List<d>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new d(p));
        }
        return res;
    }

    public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
}