public enum Scoring {
    public static func score(moves: Int, capsulesCollected: Int, parMoves: Int?) -> Int {
        let base = 1000
        let moveCost = 10 * moves
        let capsuleBonus = 250 * capsulesCollected
        var parBonus = 0
        if let par = parMoves, moves <= par {
            parBonus = 500
        }
        return max(0, base - moveCost + capsuleBonus + parBonus)
    }
}
