#let end_of_month(date) = {
  let year = date.year()
  let month = date.month()

  let day = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31).at(month - 1)
  if month == 2 and calc.rem(year, 4) == 0 and (calc.rem(year, 100) != 0 or calc.rem(year, 400) == 0 ) {
    day += 1
  }

  datetime(year: year, month: month, day: day)
}

#let pad_with_zero(n, len) = {
  let s = str(n)
  if s.len() < len {
    ("0" * (len - s.len())) + s
  } else {
    s
  }
}

#let add_comma(int) = {
  str(int).rev().replace(regex("\d{3}"), m => m.text + ",").rev().replace(regex("^,"), "")
}

// font [string]: フォント
// date [datetime]: 発行日
// due-date [datetime]: 支払期限
// serial [int]: 請求書番号に振るシリアル・ナンバー
// tax-rate [float]: 消費税率
// client-name [string]: クライアント名, required
// client-details [string]: クライアント詳細, required
// vendor-name [string]: 発行者名, required
// vendor-details [string]: 発行者詳細, required
// seal [string]: 印鑑画像へのパス
// transfer-destination [dictionary]: (bank [string]: 銀行名, branch [string]: 支店名,
//                                    account [string]: 口座番号, name [string]: 口座名義),
//                                    required
// comment: 備考欄
// items [[]dictionary]: [(name [string]: 商品名, amount [int]: 数量, price [int]: 単価, unit [string]: 単位), ...]

#let doc(
  font: none,
  date: datetime.today(),
  due-date: end_of_month(datetime.today()),
  serial: 1,
  tax-rate: .1,
  include-tax: false,
  client-name: none,
  client-details: none,
  vendor-name: none,
  vendor-details: none,
  seal: none,
  transfer-destination: (
    bank: none,
    branch: none,
    account: none,
    name: none,
  ),
  comment: none,
  items: (),
) = {
  let total = items.map(item => item.price * item.amount).sum(default: 0)
  let tax = calc.floor(total * tax-rate / if include-tax { 1 + tax-rate } else { 1 })
  let total-without-tax = if include-tax { total - tax } else { total }
  let total-with-tax = total-without-tax + tax

  set text(font: font) if font != none
  set text(size: 10pt)
  [ = 請求書 ]
  v(1em)
  grid(
    columns: (4fr, 3fr),
    gutter: 10pt,
    {
      set text(size: 12pt)
      client-name
      set text(size: 10pt)
      v(.1em)
      client-details
      v(1em)
      [ 下記の通りご請求申し上げます。 ]
      show table.cell: it => {
        if it.y == 0 {
          set text(white)
          it
        } else {
          it
        }
      }
      table(
        align: (right,) * 3,
        columns: (auto,) * 3,
        fill: (_, y) => if y == 0 {black},
        inset: (left: 1.5em, right: .5em, y: .5em),
        stroke: (x, y) => {
          if y == 0 {
            black
          } else {
            (y: black)
          }
        },
        [ 小計 ],
        [ 消費税 ],
        [ 合計金額 ],
        [ #{add_comma(total-without-tax)} 円 ],
        [ #{add_comma(tax)} 円 ],
        [ #{add_comma(total-with-tax)} 円 ],
      )
      v(1em)
      grid(
        align: left,
        columns: (60pt, auto),
        row-gutter: 18pt,
        { [ 振込期日 ] },
        { [ #{due-date.year()}年#{due-date.month()}月#{due-date.day()}日 ] },
        { [ 振込先 ] },
        grid(
          align: left,
          columns: (auto, auto),
          gutter: 6pt,
          row-gutter: 6pt,
          { [ 銀行名: ] },
          { transfer-destination.bank },
          { [ 支店名: ] },
          { transfer-destination.branch },
          { [ 口座番号: ] },
          { transfer-destination.account },
          { [ 口座名義: ] },
          { transfer-destination.name },
        )
      )
    },
    {
      grid(
        align: (left, right),
        columns: (1fr, auto),
        row-gutter: 6pt,
        { [ 日付: ] },
        { [ #{date.year()}年#{date.month()}月#{date.day()}日 ] },
        { [ 請求書番号: ] },
        { [ #{pad_with_zero(date.year(), 4)}#{pad_with_zero(date.month(), 2)}#{pad_with_zero(date.day(), 2)}-#{pad_with_zero(serial, 3)} ] }
      )
      v(1em)
      set text(size: 12pt)
      vendor-name
      set text(size: 10pt)
      v(.1em)
      vendor-details
      if seal != none {
        place(
          top + right,
          dx: 10pt,
          dy: 40pt,
          image(
            seal,
            width: 70pt,
          ),
        )
      }
    }
  )

  v(1em)
  show table.cell: it => {
    if it.y == 0 {
      set text(white)
      it
    } else {
      it
    }
  }
  table(
    align: (left,) + (right,) * 3,
    columns: (1fr,) + (auto,) * 3,
    fill: (_, y) => {
      if y == 0 {
        black
      } else if calc.odd(y) {
        white
      } else {
        rgb("#ddd")
      }
    },
    inset: (x, _) => {
      if x == 0 {
        (left: .5em, right: 1.5em, y: .5em)
      } else if x == 3 {
        (left: 1.5em, right: .5em, y: .5em)
      } else {
        (x: 1.5em, y: .5em)
      }
    },
    stroke: (_, y) => (
      top: if y <= 1 { 1pt } else { 0pt },
      bottom: 1pt,
    ),
    table.header(
      [ 詳細 ], [ 数量 ], [ 単価 ], [
        金額 
        #if include-tax {
          [ (内税) ]
        } else {
          [ (外税) ]
        }
      ]
    ),
    ..for item in items {(
      item.name,
      [ #{add_comma(item.amount)}#{if "unit" in item.keys() { item.unit } else { "個" }} ],
      [ #{add_comma(item.price)}円 ],
      [ #{add_comma(item.amount * item.price)}円 ],
    )}
  )

  v(1em)
  line(
    length: 100%,
    stroke: 2pt + rgb("#ddd"),
  )
  if comment != none {
    comment
  }
}

