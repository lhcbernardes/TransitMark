//
//  TransitMarkWidgetBundle.swift
//  TransitMarkWidget
//

import WidgetKit
import SwiftUI

@main
struct TransitMarkWidgetBundle: WidgetBundle {
    var body: some Widget {
        TransitMarkWidget()
        TransitMarkWidgetLiveActivity()
    }
}
