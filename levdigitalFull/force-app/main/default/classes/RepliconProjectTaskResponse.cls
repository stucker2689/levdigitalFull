//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//

public class RepliconProjectTaskResponse {

	public class Task {
		public String displayText;
		public String uri;
	}

	public List<d> d;

	public class ActualTimeEntryDateRange {
		public EndDate endDate;
		public EndDate startDate;
	}

	public class d {
		public ActualHoursTotal actualHoursTotal;
		public ActualTimeEntryDateRange actualTimeEntryDateRange;
		public Boolean isClosed;
		public Task task;
	}

	public class ActualHoursTotal {
		public Integer hours;
		public Integer microseconds;
		public Integer milliseconds;
		public Integer minutes;
		public Integer seconds;
	}

	public class EndDate {
		public Integer day;
		public Integer month;
		public Integer year;
	}

	
	public static RepliconProjectTaskResponse parse(String json) {
		return (RepliconProjectTaskResponse) System.JSON.deserialize(json, RepliconProjectTaskResponse.class);
	}
}