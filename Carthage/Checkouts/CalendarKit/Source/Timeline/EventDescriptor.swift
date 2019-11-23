import Foundation

public protocol EventDescriptor: AnyObject {
  var startDate: Date {get set}
  var endDate: Date {get set}
  var isAllDay: Bool {get}
  var text: String {get}
  var attributedText: NSAttributedString? {get}
  var font : UIFont {get}
  var color: UIColor {get}
  var textColor: UIColor {get}
  var backgroundColor: UIColor {get}
  var editedEvent: EventDescriptor? {get set}
  func makeEditable() -> EventDescriptor
  func commitEditing()
}
