import CoreGraphics
import Foundation

enum DownloadedDotPuzzleArtwork {
    static func referenceArt(sheet: String, slot: Int) -> DotPuzzleReferenceArt? {
        let assetName: String
        switch sheet {
        case "D1/D2": assetName = "dot_reference_d1d2"
        case "D3": assetName = "dot_reference_d3"
        case "D4": assetName = "dot_reference_d4"
        case "D5": assetName = "dot_reference_d5"
        case "D6": assetName = "dot_reference_d6"
        case "D7": assetName = "dot_reference_d7"
        default: return nil
        }

        let index = slot - 1
        guard index >= 0, index < 15 else { return nil }
        return DotPuzzleReferenceArt(
            assetName: assetName,
            column: index % 5,
            row: index / 5,
            columns: 5,
            rows: 3
        )
    }

    static func trail(sheet: String, slot: Int, expectedCount: Int) -> [CGPoint] {
        guard let encoded = encodedTrails["\(sheet):\(slot)"],
              let data = Data(base64Encoded: encoded),
              data.count == expectedCount * 2 else { return [] }

        let bytes = [UInt8](data)
        return stride(from: 0, to: bytes.count, by: 2).map { index in
            CGPoint(
                x: CGFloat(bytes[index]) / 255,
                y: CGFloat(bytes[index + 1]) / 255
            )
        }
    }

    private static let encodedTrails: [String: String] = [
        "D1/D2:1": "kBV/JIo5hWZvjEicPYpIs1LfYeRsw3jngsGM5JK3mYuiZcJQtiejFw==",
        "D1/D2:2": "dRVYNzhhLJJYpWWsMqE7wmjYntnLxcmcr36ZYIk9",
        "D1/D2:3": "hBVUN0pnOXkebyuiYaFAvTnUcMeCwpnipLKn4NDO0KzZgs1owmm5Lg==",
        "D1/D2:4": "jBVrNFpdPntGmV2sZ81w34DVj8+esrilxYevY6Y3",
        "D1/D2:5": "VRVIQUZzUaBR0W3onuK7u7aJr7Gco6t4sESoIX0q",
        "D1/D2:6": "YCJqOFpOSXAjfximMMhV2oDcqtrNytfb4rrbqMirxpPDcJ58i1t+OQ==",
        "D1/D2:7": "TRhHPz1qJZMowUrhbteW4b3W3bXRh79cwDOmG3kh",
        "D1/D2:8": "hUB9WWNdS2dKhjiMJJErrDfGSdxk5YLnoOe84M3K1K7Km9SS2oDAer6XrpCxc59inUk=",
        "D1/D2:9": "zByiWIMgYk4zOjJRMlQell+zg82oz8fR0bnUitlV",
        "D1/D2:10": "zSSKOUU4J0tuQEJhdUdVbjGpP8hK1ZLau8uwxOagupmVaaFHrEG1Mw==",
        "D1/D2:11": "GT8fVyBzIY8lqjW9TLVbsXC/gqycq7G0yL7esuCj4IfIgMtkz02yTqhAjEBvQFJANUA=",
        "D1/D2:12": "GyckTih5KJwry1XTcdKUw7TNwdDmxc2exXG7UKI4nlqIWHxRfydNJw==",
        "D1/D2:13": "Rx9AQzloJYEYoCe3Ntha3G6+kLmh1cPY0bjmp+GDvH60Wqo2lh9vHw==",
        "D1/D2:14": "zz/OXadVhEhmXUxzLGEcey+NPqZjroCslruTnqS4vaq0ldN+6YHcYA==",
        "D1/D2:15": "bhhJHS40J1gkfiGlGcUx3FHfcNGT2LHm0dbkwdaiz4PTXtI3uh6VGQ==",
        "D3:1": "ihdwKFU4PEo7Y1VyaIpjpWnEf9uE2HG/bqGBjJ2Au4jMeMJbs0CkJg==",
        "D3:2": "HSocTxt0OIc+rU3McdKHvKHNyNLVsNeH0mLnRNRUslCQP21BSTYsSQ==",
        "D3:3": "YFc/Xyh3IZgnuijXOt9Y4nvkm+ax28O+263Hoq2ds7uls6aPnW+CWw==",
        "D3:4": "jCZjKlM+SllqaU+MRaJBeB2DJZs4tlnQhdet2M3J0Z7Nct9N3SiyLQ==",
        "D3:5": "rCqJNqRAs1yyg6CkfKF7fI9dalZMYjWAK54bsy/GTtJjuIayq7W70dvG56rZiNhjv0c=",
        "D3:6": "yhiSLlswTlpzhEirQ8Jl5XfRkKulh8lbrEZyQ6kt",
        "D3:7": "exd4Oo1dgHxff02MYJdrs2fciOh13Hm/kduIu4mlrJSlbJNHsjigIQ==",
        "D3:8": "pBd6MVE0WWp3imC6U4Y/nEbPaeWb47HAuY27dLlJ",
        "D3:9": "lChwKE4tQkw3ayaIF6YkvTLQSsxfvXu1mrmi0rzSzL3ns+iW3Hi9cLtPsU6tcJlhkz8=",
        "D3:10": "dRdbHzw9N1hFfF+YT79J33Thm+C21byyqpG2taevn5O6eshZuTGgIA==",
        "D3:11": "hxdfKkpRPnVMnUvKWMlT3nbigNmKtaaVuHnCTrEl",
        "D3:12": "ti+PR5t0emlJaS6MHKAnwU3MZsOMypeluYPhbtpH",
        "D3:13": "GycmSxtyKphJs1LLcNCVxKjKw6/flOVtvmOZYn1DakhiaTtgQ0o/Og==",
        "D3:14": "Zhc/PDtxM6VIwmPhpea8r816q4ivzJe0k3zCUZ0u",
        "D3:15": "gBdpLEMgOzg4ZEGNTrdL4GLFYeV4yYnPldeiyqfmtrrEk7R5lmiSOw==",
        "D4:1": "LRcmUCeLXpxs4IXJl8iz3MLn0qPWfrGBiGWHNmUn",
        "D4:2": "TBcxPk1eZIRJi1mxWN+A26HdraydfLlWzjClHHgm",
        "D4:3": "ixdfQ053Tn9ahDGzU7Fxd2WoaedzrIKjlXuYvKmwp3W8p793xnC+OQ==",
        "D4:4": "cEVMTSJMHG00jkqnbquUprqb1rnboNqGtIaTbotX",
        "D4:5": "lyNpNzo3OmYijEBtMo1BhSm3QN1s4J/fv9fKorZvw2vAZcJX2m6tTQ==",
        "D4:6": "WjAxQRloGZQxt1LLaMF+xJ3Ip7jHl+VyymCxNokw",
        "D4:7": "eCJMPDBkRYpKlBilN85r26LY1MbcnKeQw4PMVqgz",
        "D4:8": "wSyePHtCd1yVY6tZo46Nvma5WKdBpy++MdJs0qjSo7qzib5mzVHRQA==",
        "D4:9": "jBdlRFVkG24jk0yodb1v4JLisdTS5OW91IbJULwv",
        "D4:10": "oxdnID06SnMrjTzGOdtU23faleO62MvH2Zeufb1I",
        "D4:11": "ahdAVVe3cOdru0d6lZaTs3madKNfoaq6tYrDaXZl",
        "D4:12": "ehdYM0JJal57gnywitOL46nUva25iZWHnmCsNqci",
        "D4:13": "ehdqKFw+ZF1Ye06iVMlv5JDkqMywpal+lWCjO5Ek",
        "D4:14": "cxhNMCE9HWkwklqRar135prSn6K5jdhz50nNIqAZ",
        "D4:15": "jBdpIVtAXmBafk+aN6QdoTLGWNZy6IfWpeWkw7OdsYHWc91Nu0OtGw==",
        "D5:1": "fk5bWT1sHF4cejePUZphsHahhaOUr6iVu4rYoeSH24rfoNCEwmKkUw==",
        "D5:2": "Vhg1TDGCJMVa55rOkclO2lLAe6ugpqFryj3NKpgd",
        "D5:3": "bxdoP2tYNp9h27XXlZibOcyArzU=",
        "D5:4": "jjpvWzxcLVoXTx56K6lEu2q0g7GXpsea5XToT71A",
        "D5:5": "1R6ZLF40cW5dn19yMVsXkzPKad+k3b/Tzr7Pg91P",
        "D5:6": "hBhyWVNFTZZKtG/LQKdek1IzfWmQJqVQtFjZWLGumtu3m85Tv0WbXg==",
        "D5:7": "zimdNm83ampnkk+GMV4XjS29YcyW1cjVx7LRgt5W",
        "D5:8": "MzQzWB1pPotboV+qYrV5roOop8LWycSwmprAkOd3zGTMQaJZfXBZUg==",
        "D5:9": "Vhc9QUB0QpQftU3EXuiBxLC90p3Tdt9Gs0CPYn40",
        "D5:10": "NScaTReEIbhI1nnIpcvV1eKqysCirXikUahXdF0/",
        "D5:11": "iRd1NHRqTJRRyn3oq860mJFqnTY=",
        "D5:12": "fDZSSjJpNJg+w5bHxbbDl75vpEw=",
        "D5:13": "gRd4K21HXW5HckGdRshk5Y3ircS9naiNn2mTQIsq",
        "D5:14": "tBeULotMeXBikkizRMhtyG/Zg96ozriqwIHBV8U1",
        "D5:15": "OhcjTjGKO6lTt3LVjLeOx6TNtMHP6Nezu3+IYFFG",
        "D6:1": "lhh/TnmNOJslykDHTM5x35KwqdqgosuWzFrSN6ZD",
        "D6:2": "cBdYJE0+TVxReWKQe5ySrqHGn+Os1rG6rKCjjZF2f1+UU6ZIoyyMHQ==",
        "D6:3": "mReHNpZbk3N0Xk9rN4tZjVewach553LbbbOHt3GflpeodalLwD6+JA==",
        "D6:4": "UkQ9VjeAOpY6wkHobeiZ6MTlxLnIlMV5uVSNVGlU",
        "D6:5": "eRdLQmx4Unpdo37om6OWgaltsjE=",
        "D6:6": "bRdZNlBgO2dAg1qZVLhs3JTnuNLIqr2EqWarP40j",
        "D6:7": "bxdDND9nH5JSo4mfv57fd8tGoyY=",
        "D6:8": "ZRdCLDtWVnFVklK8Yd+A3I7iqdnCt7yOnW6aS40l",
        "D6:9": "YSg8Mx9OJ25Igm5/c41unIKYjZqBvJ3Vw8/ftOCU4nbVWr5GoTaILg==",
        "D6:10": "ZhZRQUZsUpRVx13ijeiyzK+skZqYb6VDkhyITmdE",
        "D6:11": "uSd6NkJWGYk0vWq+l9e9scmB6Ek=",
        "D6:12": "WhdQOi5kNZo02GPooOjN1cyYwme6WKqLkJqDdm5L",
        "D6:13": "ZxdHJEQuKlg/fjuoTM504J/gyuPDwZmvhYuGXms0",
        "D6:14": "ixaCQl1jWo1Uwl7gfbaakalnoTk=",
        "D6:15": "gRh5SV87N1Mtihu5LeZq6Kfn4uLkptdzwUeZPIhJ",
        "D7:1": "vhecTFRNIX0kwTXMVOR0ypnbptS7ttZ7x0TLOKxA",
        "D7:2": "hxZqJFAyS0dHZlx9TppCuEXZYeR75pvkvOK9wqypooqkcq5XpUWTKQ==",
        "D7:3": "bBdoTUBzN6dP3IvouMnRkrNkizs=",
        "D7:4": "fhZbOlBuTqR0u4Loi7ayoLBppTU=",
        "D7:5": "NRgwUBiCOrB75tjh4ouwRIAyV0Q=",
        "D7:6": "bWgzezW0Jtlj56Tm39POsOGArW0=",
        "D7:7": "bxdwOVJORW9OjlK0V9p26Jzkq8avoLp/tVyfP340",
        "D7:8": "cDU7RBlwJ6RWwo7JxLvmj9hbqT0=",
        "D7:9": "txyUNIFZc3FEd0FSNGw4miC+K9VM2Gi1lausxsm+x5uye9N14FLYKw==",
    ]
}
