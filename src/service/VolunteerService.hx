package service;
import Common;
import sugoi.mail.Mail;
import tink.core.Error;

/**
 * Volunteer Service
 * @author web-wizard
 */
class VolunteerService 
{

	public static function deleteVolunteerRole(role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;

		if ( db.Volunteer.manager.count($volunteerRole == role) == 0 ) {

			var roleId = Std.string(role.id);
			role.lock();
			role.delete();

			//Let's find all the multidistribs that have this role in volunteerRolesIds
			var roleIdInMultidistribs = Lambda.array( db.MultiDistrib.manager.search( $group == role.group && $volunteerRolesIds.like("%" + roleId + "%"), true ) );
			for ( multidistrib in roleIdInMultidistribs ) {

				var roleIds = multidistrib.volunteerRolesIds.split(',');
				if ( roleIds.remove(roleId) ) {

					multidistrib.volunteerRolesIds = roleIds.join(',');
					multidistrib.update();
				}
			}
		}
		else {

			throw new tink.core.Error(t._("You can't delete this role because there are volunteers assigned to this role. You need to delete the volunteers first."));
		}
	}

	public static function updateVolunteers(multidistrib: db.MultiDistrib, rawData: Map<String, Dynamic>) {

		var t = sugoi.i18n.Locale.texts;

		var userIdByRoleId = new Map<Int, Int>();
		var uniqueUserIds = [];
		var volunteerRoles = multidistrib.getVolunteerRoles();
		if (volunteerRoles == null) {

			throw new Error(t._("You need to first select the volunteer roles for this distribution."));
		}

		for ( role in volunteerRoles ) {

			var userId = rawData[Std.string(role.id)];
			if ( !Lambda.has(uniqueUserIds, userId) ) {

				if( userId != null ) {
					uniqueUserIds.push(userId);
				}
				userIdByRoleId[role.id] = userId;
			}
			else {

				throw new Error(t._("A volunteer can't be assigned to multiple roles for the same distribution!"));
			}				
		}

		var volunteers = multidistrib.getVolunteers();
		for ( volunteer in volunteers ) {

			var userIdForThisRole = userIdByRoleId[volunteer.volunteerRole.id];
			if ( userIdForThisRole != volunteer.user.id ) {
			
				volunteer.lock();
				if ( userIdForThisRole == null ) {

					volunteer.delete();
				} 
				else {

					var volunteerCopy = new db.Volunteer();
					volunteerCopy.user = db.User.manager.get(userIdForThisRole);
					volunteerCopy.multiDistrib = multidistrib;
					volunteerCopy.volunteerRole = volunteer.volunteerRole;					
					volunteerCopy.insert();		
					volunteer.delete();				
				}

				userIdByRoleId.remove(volunteer.volunteerRole.id);
			
			}
			else {
				
				userIdByRoleId.remove(volunteer.volunteerRole.id);
			}
		}

		for ( roleId in userIdByRoleId.keys() ) {

			var userIdForThisRole = userIdByRoleId[roleId];
			if ( userIdForThisRole != null ) {

				var volunteer = new db.Volunteer();
				volunteer.user = db.User.manager.get(userIdForThisRole);
				volunteer.multiDistrib = multidistrib;
				volunteer.volunteerRole = db.VolunteerRole.manager.get(roleId);					
				volunteer.insert();

			}					
		}
		
	}

	public static function addUserToRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole) {

		var t = sugoi.i18n.Locale.texts;
		if ( multidistrib == null ) throw new Error(t._("Multidistribution is null"));
		if ( role == null ) throw new Error(t._("Role is null"));

		//Check that the user is not already assigned to a role for this multidistrib
		var userAlreadyAssigned = multidistrib.getVolunteerForUser(user);
		if ( userAlreadyAssigned != null ) {

			throw new tink.core.Error(t._("A volunteer can't be assigned to multiple roles for the same distribution!"));
		}
		else {
			
			var existingVolunteer = multidistrib.getVolunteerForRole(role);
			if ( existingVolunteer == null ) {
				var volunteer = new db.Volunteer();
				volunteer.user = user;
				volunteer.multiDistrib = multidistrib;
				volunteer.volunteerRole = role;					
				volunteer.insert();
			}
			else {

				throw new tink.core.Error(t._("This role is already filled by a volunteer!"));
			}				
		}
				

	}

	public static function removeUserFromRole(user: db.User, multidistrib: db.MultiDistrib, role: db.VolunteerRole, reason: String ) {

		var t = sugoi.i18n.Locale.texts;
		if ( user != null && multidistrib != null && role != null ) {

			//Look for the volunteer for that user
			var foundVolunteer = multidistrib.getVolunteerForUser(user);
			if ( foundVolunteer != null && foundVolunteer.volunteerRole.id == role.id ) {

				foundVolunteer.lock();
				foundVolunteer.delete();

				//Send notification email to either the coordinators or all the members depending on the current date
				var mail = new Mail();
				mail.setSender(App.config.get("default_email"),"Cagette.net");
				var now = Date.now();
				var alertDate = DateTools.delta( multidistrib.distribStartDate, - 1000.0 * 60 * 60 * 24 * multidistrib.group.vacantVolunteerRolesMailDaysBeforeDutyPeriod );
				var message: String = t._( "::fullname:: has left the role ::role:: for the following reason:<br/>::reason::<br/>",
				                         { fullname : user.getName(), role : role.name, reason : reason } );				
				message += t._("This role needs to be filled.");

				if ( now.getTime() <=  alertDate.getTime() ) {

					//Recipients are the coordinators
					var adminUsers = service.GroupService.getGroupMembersWithRights( multidistrib.group, [ Right.GroupAdmin ] );
					for ( admin in adminUsers ) {

						mail.addRecipient( admin.email, admin.getName() );
						if ( admin.email2 != null ) {
							mail.addRecipient( admin.email2 );
						}
					}
				}
				else {

					var members = Lambda.array( multidistrib.group.getMembers() );
					//Recipients are all members
					for ( member in members ) {

						mail.addRecipient( member.email, member.getName() );
						if ( member.email2 != null ) {
							mail.addRecipient( member.email2 );
						}
					}
				}
				
				mail.setSubject( t._( "[::group::] A role has been left for ::date:: distribution", { group : multidistrib.group.name, date : App.current.view.hDate( multidistrib.distribStartDate ) } ) );
				mail.setHtmlBody( App.current.processTemplate("mail/message.mtt", { text: message, group: multidistrib.group  } ) );
				App.sendMail(mail);
			}
			else {
				
				throw new tink.core.Error(t._("This user is not assigned to this role!"));				
			}
		}
		else {

			throw new tink.core.Error(t._("Missing distribution or role in the url!"));
		}			
	}

	public static function updateMultiDistribVolunteerRoles(multidistrib: db.MultiDistrib, rolesIds: String) {

		var t = sugoi.i18n.Locale.texts;

		var volunteers = multidistrib.getVolunteers();

		if ( volunteers != null ) {

			var roleIds = rolesIds.split(',');
			for ( roleId in roleIds ) {

				volunteers = Lambda.array(Lambda.filter(volunteers, function(volunteer) return volunteer.volunteerRole.id != Std.parseInt(roleId)));
			}
		}
		
		if ( volunteers == null || volunteers.length == 0 ) {

			multidistrib.lock();
			multidistrib.volunteerRolesIds = rolesIds;
			multidistrib.update();
		}
		else {

			throw new tink.core.Error(t._("You can't remove some roles because there are volunteers assigned to those roles. You need to delete the volunteers first."));
		}
	}

	public static function createRoleForContract(c:db.Contract,number:Int){
		var t = sugoi.i18n.Locale.texts;
		for ( i in 1...(number+1) ) {
			
			var role = new db.VolunteerRole();
			role.name = t._("Duty period") + " " + c.name + " " + i;
			role.group = c.amap;
			role.contract = c;
			role.insert();
		
		}
	}

	public static function isNumberOfDaysValid( numberOfDays: Int, type: String ) {

		var t = sugoi.i18n.Locale.texts;

		if ( Std.is( numberOfDays, Int ) ) {
			
			switch( type ) {

				case "volunteersCanJoin":
				
					if ( numberOfDays <  7 ) {

						throw new tink.core.Error(t._("The number of days before the volunteers can join a duty period needs to be greater than 6 days."));
					}
					else if ( numberOfDays > 181 ) {

						throw new tink.core.Error(t._("The number of days before the volunteers can join a duty period needs to be lower than 181 days."));
					}

				case "instructionsMail":

					if ( numberOfDays <  2 ) {

						throw new tink.core.Error(t._("The number of days before the duty periods to send the instructions mail to all the volunteers needs to be greater than 1 day."));
					}
					else if ( numberOfDays > 15 ) {

						throw new tink.core.Error(t._("The number of days before the duty periods to send the instructions mail to all the volunteers needs to be lower than 15 days."));
					}

				case "vacantRolesMail":

					if ( numberOfDays <  2 ) {

						throw new tink.core.Error(t._("The number of days before the duty periods to send the vacant roles mail to all members needs to be greater than 1 day."));
					}
					else if ( numberOfDays > 15 ) {

						throw new tink.core.Error(t._("The number of days before the duty periods to send the instructions mail to all members needs to be lower than 15 days."));
					}
			}
		}
		else {

			throw new tink.core.Error(t._("One or more numbers of days you entered is not an integer. You can only use integers. "));
		}	
	}
}