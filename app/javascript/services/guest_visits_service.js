// Guest Visits Service
// Holds the check-ins a traveller makes before they have an account, so the
// walk survives a reload and can be replayed into the database at sign-in.
//
// Only location uuids and the time they were marked are kept — never a name, a
// coordinate, or anything else that identifies the traveller or where they are.

const VISITS_KEY = "usput_guest_visits"

export class GuestVisitsService {
  isLoggedIn() {
    const meta = document.querySelector('meta[name="user-logged-in"]')
    return meta?.content === "true"
  }

  getVisits() {
    try {
      const data = localStorage.getItem(VISITS_KEY)
      const parsed = data ? JSON.parse(data) : []
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return []
    }
  }

  visitedIds() {
    return new Set(this.getVisits().map(visit => visit.id))
  }

  has(locationId) {
    return this.visitedIds().has(locationId)
  }

  add(locationId) {
    if (!locationId || this.has(locationId)) return this.getVisits()

    const visits = [ ...this.getVisits(), { id: locationId, visitedAt: new Date().toISOString() } ]
    this.save(visits)
    return visits
  }

  remove(locationId) {
    this.save(this.getVisits().filter(visit => visit.id !== locationId))
  }

  clear() {
    try {
      localStorage.removeItem(VISITS_KEY)
    } catch (error) {
      console.error("Failed to clear guest visits:", error)
    }
  }

  // What the login and registration forms post, matching the hidden-field shape
  // the travel profile and plans already use.
  forSignIn() {
    return JSON.stringify(this.getVisits())
  }

  save(visits) {
    try {
      localStorage.setItem(VISITS_KEY, JSON.stringify(visits))
    } catch (error) {
      console.error("Failed to save guest visits:", error)
    }
  }
}

export const guestVisitsService = new GuestVisitsService()
