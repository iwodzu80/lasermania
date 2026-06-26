public struct LevelDefinition: Codable, Equatable, Sendable {
    public struct LegendEntry: Codable, Equatable, Sendable {
        public let type: String
        public let dir: String?

        public init(type: String, dir: String? = nil) {
            self.type = type
            self.dir = dir
        }
    }

    public let id: String
    public let name: String
    public let parMoves: Int?
    public let sensorModel: String?
    public let legend: [String: LegendEntry]?
    public let layout: [String]

    public init(
        id: String,
        name: String,
        parMoves: Int? = nil,
        sensorModel: String? = nil,
        legend: [String: LegendEntry]? = nil,
        layout: [String]
    ) {
        self.id = id
        self.name = name
        self.parMoves = parMoves
        self.sensorModel = sensorModel
        self.legend = legend
        self.layout = layout
    }
}
