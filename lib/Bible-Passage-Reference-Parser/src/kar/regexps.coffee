bcv_parser::regexps.space = "[\\s\\xa0]"
bcv_parser::regexps.escaped_passage = ///
	(?:^ | [^\x1f\x1e\dA-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ] )	# Beginning of string or not in the middle of a word or immediately following another book. Only count a book if it's part of a sequence: `Matt5John3` is OK, but not `1Matt5John3`
		(
			# Start inverted book/chapter (cb)
			(?:
				  (?: ch (?: apters? | a?pts?\.? | a?p?s?\.? )? \s*
					\d+ \s* (?: [\u2013\u2014\-] | through | thru | to) \s* \d+ \s*
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )?\s* )
				| (?: ch (?: apters? | a?pts?\.? | a?p?s?\.? )? \s*
					\d+ \s*
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )?\s* )
				| (?: \d+ (?: th | nd | st ) \s*
					ch (?: apter | a?pt\.? | a?p?\.? )? \s* #no plurals here since it's a single chapter
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )? \s* )
			)? # End inverted book/chapter (cb)
			\x1f(\d+)(?:/\d+)?\x1f		#book
				(?:
				    /\d+\x1f				#special Psalm chapters
				  | [\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014]
				  | kar (?! [a-z] )		#could be followed by a number
				  | တၢ်မၤလိ | and | အဆၢ | ff | -
				  | [a-e] (?! \w )			#a-e allows 1:1a
				  | $						#or the end of the string
				 )+
		)
	///gi
# These are the only valid ways to end a potential passage match. The closing parenthesis allows for fully capturing parentheses surrounding translations (ESV**)**. The last one, `[\d\x1f]` needs not to be +; otherwise `Gen5ff` becomes `\x1f0\x1f5ff`, and `adjust_regexp_end` matches the `\x1f5` and incorrectly dangles the ff.
bcv_parser::regexps.match_end_split = ///
	  \d \W* kar
	| \d \W* ff (?: [\s\xa0*]* \.)?
	| \d [\s\xa0*]* [a-e] (?! \w )
	| \x1e (?: [\s\xa0*]* [)\]\uff09] )? #ff09 is a full-width closing parenthesis
	| [\d\x1f]
	///gi
bcv_parser::regexps.control = /[\x1e\x1f]/g
bcv_parser::regexps.pre_book = "[^A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ]"

bcv_parser::regexps.first = "(?:1|[၁1])\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.second = "(?:2|[၂2])\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.third = "(?:3|[၃3])\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.range_and = "(?:[&\u2013\u2014-]|and|-)"
bcv_parser::regexps.range_only = "(?:[\u2013\u2014-]|-)"
# Each book regexp should return two parenthesized objects: an optional preliminary character and the book itself.
bcv_parser::regexps.get_books = (include_apocrypha, case_sensitive) ->
	books = [
		osis: ["Ps"]
		apocrypha: true
		extra: "2"
		regexp: ///(\b)( # Don't match a preceding \d like usual because we only want to match a valid OSIS, which will never have a preceding digit.
			Ps151
			# Always follwed by ".1"; the regular Psalms parser can handle `Ps151` on its own.
			)(?=\.1)///g # Case-sensitive because we only want to match a valid OSIS.
	,
		osis: ["Gen"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံာ်တၢ်ကဲထီၣ်အခီၣ်ထံး|1(?:\.[\s\xa0]*?|[\s\xa0]*)?မိၤၡ့|၁[\s\xa0]*?မိၤၡ့|Gen)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Exod"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်စီၤမိၤၡ့ခံဘ့ၣ်တဘ့ၣ်[\s\xa0]*(?:2\.?|၂)[\s\xa0]*မိၤ|ာ်တၢ်ဟးထီၣ်ကွံာ်)|2(?:\.[\s\xa0]*?|[\s\xa0]*)?မိၤၡ့|၂[\s\xa0]*?မိၤၡ့|Exod)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Bel"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Bel)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Lev"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်စီၤမိၤၡ့သၢဘ့ၣ်တဘ့ၣ်[\s\xa0]*(?:3\.?|၃)[\s\xa0]*မိၤ|ာ်တၢ်ဘူၣ်ထီၣ်ဘါထီၣ်)|3(?:\.[\s\xa0]*?|[\s\xa0]*)?မိၤၡ့|၃[\s\xa0]*?မိၤၡ့|Lev)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Num"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်စီၤမိၤၡ့လွံၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*(?:4\.?|၄)[\s\xa0]*မိၤ|ာ်တၢ်ဂံၢ်)|4(?:\.[\s\xa0]*?|[\s\xa0]*)?မိၤၡ့|၄[\s\xa0]*?မိၤၡ့|Num)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Sir"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Sir)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Wis"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Wis)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Lam"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်သးသယုၢ်တၢ်[\s\xa0]*[\s\xa0]*သး|ာ်သးသယုၢ်တၢ်)|Lam)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["EpJer"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:EpJer)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Rev"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:တၢ်လီၣ်ဖျါ[\s\xa0]*[\s\xa0]*လီၣ်|လံာ်လီၣ်ဖျါ|Rev)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["PrMan"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:PrMan)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Deut"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:5(?:\.(?:[\s\xa0]*မိၤၡ့[\s\xa0]*လံၥ်စီၤမိၤၡ့ယဲၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:5\.?|၅)|မိၤၡ့[\s\xa0]*လံၥ်စီၤမိၤၡ့ယဲၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:5\.?|၅))|[\s\xa0]*မိၤၡ့[\s\xa0]*လံၥ်စီၤမိၤၡ့ယဲၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:5\.?|၅)|မိၤၡ့[\s\xa0]*လံၥ်စီၤမိၤၡ့ယဲၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:5\.?|၅))[\s\xa0]*မိၤ|၅(?:[\s\xa0]*မိၤၡ့[\s\xa0]*လံၥ်စီၤမိၤၡ့ယဲၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:5\.?|၅)|မိၤၡ့[\s\xa0]*လံၥ်စီၤမိၤၡ့ယဲၢ်ဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:5\.?|၅))[\s\xa0]*မိၤ|လံာ်သိၣ်လီၤသီလီၤတၢ်|Deut)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Josh"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယိၤၡူ[\s\xa0]*[\s\xa0]*[\s\xa0]*|ာ်စီၤယိၤ)ၡူ|ယိၤၡူ|Josh)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Judg"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ၦၤစံၣ်ညီၣ်ကွီၢ်[\s\xa0]*စံၣ်ညီၣ|ာ်ပှၤစံၣ်ညီၣ်ကွီၢ)်|Judg)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ruth"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်နီၢ်ရူၤသး[\s\xa0]*[\s\xa0]*[\s\xa0]*ရူၤ|ာ်နီၢ်ရူၤသး)|Ruth)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Esd"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1Esd)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Esd"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2Esd)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Isa"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယၡါယၤ[\s\xa0]*[\s\xa0]*[\s\xa0]*ၡါ|ာ်ယၡါယၤ)|ယၡါယၤ|Isa)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Sam"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်ၡမူၤအ့လးခံဘ့ၣ်တဘ့ၣ်[\s\xa0]*(?:2\.?|၂)[\s\xa0]*မူၤ|ာ်စီၤၡမူၤအ့လးခံဘ့ၣ်တဘ့ၣ်)|2(?:ၡမူၤအ့လး|Sam))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Sam"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်ၡမူၤအ့လးအခီၣ်ထံးတဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*မူၤ|ာ်စီၤၡမူၤအ့လးအခီၣ်ထံးတဘ့ၣ်)|1(?:ၡမူၤအ့လး|Sam))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Kgs"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်စီၤပၤခံဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*စီၤပၤ|ာ်စီၤပၤခံဘ့ၣ်တဘ့ၣ်)|2Kgs)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Kgs"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်စီၤပၤအခီၣ်ထံးတဘ့ၣ်[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*စီၤပၤ|ာ်စီၤပၤအခီၣ်ထံးတဘ့ၣ်)|1Kgs)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Chr"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်ကွဲးနီၣ်တၢ်ခံဘ့ၣ်တဘ့ၣ်[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ကွဲး|ာ်ကွဲးနီၣ်တၢ်ခံဘ့ၣ်တဘ့ၣ်)|(?:2\.?|၂)[\s\xa0]*ကွဲးနီၣ်တၢ်|2Chr)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Chr"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:လံ(?:ၥ်ကွဲးနီၣ်တၢ်အခီၣ်ထံးတဘ့ၣ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ကွဲး|ာ်ကွဲးနီၣ်တၢ်အခီၣ်ထံးတဘ့ၣ်)|(?:1\.?|၁)[\s\xa0]*ကွဲးနီၣ်တၢ်|1Chr)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezra"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ဧ့စြၤ[\s\xa0]*[\s\xa0]*[\s\xa0]*ဧ့|ာ်စီၤဧ့စြၤ)|Ezra)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Neh"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်နဃ့မယၤ[\s\xa0]*[\s\xa0]*ဃ့|ာ်စီၤနဃ့မယၤ)|Neh)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["GkEsth"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:GkEsth)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Esth"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်နီၢ်အ့ၤစတၢ်[\s\xa0]*အ့ၤ|ာ်နီၢ်အ့ၤစတၢ်)|Esth)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Job"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယိၤဘး[\s\xa0]*[\s\xa0]*[\s\xa0]*|ာ်စီၤယိၤ)ဘး|ယိၤဘး|Job)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ps"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံၥ်စံးထီၣ်ပတြၢၤ[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*စံး|စံးထီၣ်ပတြၢၤ|Ps)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["PrAzar"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:PrAzar)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Prov"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ာ်တၢ်ကူၣ်သ့အတၢ်|ၥ်တၢ်ကတိၤဒိ[\s\xa0]*[\s\xa0]*[\s\xa0]*)ကတိၤ|ကတိၤဒိ|Prov)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Eccl"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ၦၤစံၣ်တဲၤတဲလီၤတၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*စံၣ|ာ်ပှၤစံၣ်တဲၤတဲလီၤတၢ)်|Eccl)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["SgThree"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:SgThree)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Song"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်တၢ်သးဝံၣ်တဖၣ်အတၢ်သးဝံၣ်[\s\xa0]*တၢ|ာ်တၢ်သးဝံၣ်တဖၣ်အတၢ်သးဝံၣ)်|Song)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jer"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယံးရမံယၤ[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*ယံး|ာ်ယံးရမံယၤ)|ယံးရမံယၤ|Jer)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezek"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယဃ့းစက့လး[\s\xa0]*[\s\xa0]*[\s\xa0]*ဃ့|ာ်ယဃ့းစက့လ)း|ယဃ့းစက့လး|Ezek)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Dan"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ဒၤနံးယ့လး[\s\xa0]*[\s\xa0]*[\s\xa0]*ဒၤ|ာ်ဒၤနံးယ့လး)|ဒၤနံးယ့လး|Dan)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hos"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ဟိၤၡ့[\s\xa0]*[\s\xa0]*[\s\xa0]*ဟိၤ|ာ်ဟိၤၡ့)|ဟိၤၡ့|Hos)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Joel"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယိၤအ့လး[\s\xa0]*အ့|ာ်ယိၤအ့လး)|Joel)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Amos"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ဧၤမိၣ်[\s\xa0]*[\s\xa0]*ဧၤ|ာ်ဧၤမိၣ်)|Amos)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Obad"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ဧိၤဘါဒယၤ[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*ဧိ|ာ်ဧိၤဘါဒယ)ၤ|Obad)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jonah"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ယိၤနါ[\s\xa0]*[\s\xa0]*[\s\xa0]*|ာ်ယိၤ)နါ|Jonah)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mic"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်မံကၤ[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*မံ|ာ်မံကၤ)|Mic)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Nah"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်နၤဃူၣ်[\s\xa0]*[\s\xa0]*နၤ|ာ်နၤဃူၣ်)|Nah)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hab"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ဃ(?:ံၥ်ဃဘးကူၥ်[\s\xa0]*ဃဘး|ဘးကူၥ်)|လံာ်ဃဘးကူာ်|Hab)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Zeph"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်စဖါနယၤ[\s\xa0]*[\s\xa0]*ဖါ|ာ်စဖါနယၤ)|Zeph)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hag"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်ဃးကဲ[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*ဃး|ာ်ဃးကဲ)|Hag)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Zech"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်စကၤရယၤ[\s\xa0]*[\s\xa0]*က|ာ်စကၤရယ)ၤ|စကၤရယၤ|Zech)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mal"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံ(?:ၥ်မၤလကံ[\s\xa0]*[\s\xa0]*[\s\xa0]*မၤ|ာ်မၤလကံ)|Mal)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Matt"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လံာ်မးသဲ|မသဲ[\s\xa0]*မး|Matt|မးသဲ)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mark"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:မၢ်ကူး[\s\xa0]*[\s\xa0]*မၢ်|လံာ်မၢ်ကူး|Mark)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Luke"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:လ(?:ူၤကၣ်(?:[\s\xa0]*[\s\xa0]*လူၤ)?|ံာ်လူၤကၣ်)|Luke)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1John"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1(?:\.[\s\xa0]*ယိ(?:ၥ်ဟၣ်သိၣ်တၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ယိၤ|ၤဟၣ်)|[\s\xa0]*ယိ(?:ၥ်ဟၣ်သိၣ်တၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ယိၤ|ၤဟၣ်)|John)|၁[\s\xa0]*ယိ(?:ၥ်ဟၣ်သိၣ်တၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ယိၤ|ၤဟၣ်))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2John"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2(?:\.[\s\xa0]*ယိ(?:ၥ်ဟၣ်သိၣ်တၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ယိၤ|ၤဟၣ်)|[\s\xa0]*ယိ(?:ၥ်ဟၣ်သိၣ်တၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ယိၤ|ၤဟၣ်)|John)|၂[\s\xa0]*ယိ(?:ၥ်ဟၣ်သိၣ်တၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ယိၤ|ၤဟၣ်))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["3John"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:3(?:\.[\s\xa0]*ယိၤဟၣ်(?:သိၣ်တၢ်[\s\xa0]*(?:3\.?|၃)[\s\xa0]*ယိၤ)?|[\s\xa0]*ယိၤဟၣ်(?:သိၣ်တၢ်[\s\xa0]*(?:3\.?|၃)[\s\xa0]*ယိၤ)?|John)|၃[\s\xa0]*ယိၤဟၣ်(?:သိၣ်တၢ်[\s\xa0]*(?:3\.?|၃)[\s\xa0]*ယိၤ)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["John"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ယိၤဟၣ်(?:[\s\xa0]*[\s\xa0]*ယိၤ)?|လံာ်ယိၤဟၣ်|John)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Acts"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:တၢ်မၢဖိမၤတၢ်[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*မၤတၢ်|မၤတၢ်|Acts)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Rom"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ရိမ့ၤ(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*ရိ)?|Rom)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Cor"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2(?:\.[\s\xa0]*ကရံၣ်သူး(?:[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ကရံၣ်)?|[\s\xa0]*ကရံၣ်သူး(?:[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ကရံၣ်)?|Cor)|၂[\s\xa0]*ကရံၣ်သူး(?:[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ကရံၣ်)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Cor"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1(?:\.[\s\xa0]*ကရံၣ်သူး(?:[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ကရံၣ်)?|[\s\xa0]*ကရံၣ်သူး(?:[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ကရံၣ်)?|Cor)|၁[\s\xa0]*ကရံၣ်သူး(?:[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ကရံၣ်)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Gal"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ကလၤတံ(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*ကလၤ)?|Gal)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Eph"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:အ့းဖ့းစူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*အ့း)?|Eph)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Phil"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ဖံလံးပံၤ(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*ဖံလံး)?|Phil)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Col"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ကလီးစဲ(?:[\s\xa0]*[\s\xa0]*ကလီး)?|Col)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Thess"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2(?:\.[\s\xa0]*သ့းစၤလနံ(?:[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*သ့း)?|[\s\xa0]*သ့းစၤလနံ(?:[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*သ့း)?|Thess)|၂[\s\xa0]*သ့းစၤလနံ(?:[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*သ့း)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Thess"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1(?:\.[\s\xa0]*သ့းစၤလနံ(?:[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*သ့း)?|[\s\xa0]*သ့းစၤလနံ(?:[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*သ့း)?|Thess)|၁[\s\xa0]*သ့းစၤလနံ(?:[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*သ့း)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Tim"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2(?:\.[\s\xa0]*တံၤမသ့း(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*တံၤ)?|[\s\xa0]*တံၤမသ့း(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*တံၤ)?|Tim)|၂[\s\xa0]*တံၤမသ့း(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*တံၤ)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Tim"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1(?:\.[\s\xa0]*တံၤမသ့း(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*တံၤ)?|[\s\xa0]*တံၤမသ့း(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*တံၤ)?|Tim)|၁[\s\xa0]*တံၤမသ့း(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*တံၤ)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Titus"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:တံတူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*တံ)?|Titus)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Phlm"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ဖံၤလ့မိၣ်(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*ဖံၤ)?|Phlm)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Heb"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ဧ့ၤဘြံၤ(?:[\s\xa0]*ဧ့ၤ)?|Heb)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jas"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ယၤကိ(?:ၥ်[\s\xa0]*[\s\xa0]*ယၤ|ာ်)|Jas)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Pet"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2(?:\.[\s\xa0]*ပ့းတရူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ပ့း)?|[\s\xa0]*ပ့းတရူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ပ့း)?|Pet)|၂[\s\xa0]*ပ့းတရူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:2\.?|၂)[\s\xa0]*ပ့း)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Pet"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1(?:\.[\s\xa0]*ပ့းတရူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ပ့း)?|[\s\xa0]*ပ့းတရူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ပ့း)?|Pet)|၁[\s\xa0]*ပ့းတရူး(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*(?:1\.?|၁)[\s\xa0]*ပ့း)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jude"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:ယူဒၤ(?:[\s\xa0]*[\s\xa0]*[\s\xa0]*[\s\xa0]*ယူ)?|Jude)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Tob"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Tob)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jdt"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Jdt)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Bar"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Bar)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Sus"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Sus)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:2Macc)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["3Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:3Macc)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["4Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:4Macc)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏḀ-ỿⱠ-ⱿꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:1Macc)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)\uff08\uff09\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	]
	# Short-circuit the look if we know we want all the books.
	return books if include_apocrypha is true and case_sensitive is "none"
	# Filter out books in the Apocrypha if we don't want them. `Array.map` isn't supported below IE9.
	out = []
	for book in books
		continue if include_apocrypha is false and book.apocrypha? and book.apocrypha is true
		if case_sensitive is "books"
			book.regexp = new RegExp book.regexp.source, "g"
		out.push book
	out

# Default to not using the Apocrypha
bcv_parser::regexps.books = bcv_parser::regexps.get_books false, "none"
