# $Id$
package Handel::L10N::zh_tw;
use strict;
use warnings;
use utf8;
use vars qw(%Lexicon);

BEGIN {
    use base 'Handel::L10N';
};

%Lexicon = (
    "Language" =>
        "正體中文",

    ## Base exceptions
    "An unspecified error has occurred" =>
        "錯誤發生，情況不明",

    "The supplied field(s) failed database constraints" =>
        "給定之欄位值不符合資料庫所設立的的條件",

    "The argument supplied is invalid or of the wrong type" =>
        "給定的參數無效，或是型別錯誤",

    "Required modules not found" =>
        "未找到所需之模組",

    "The quantity requested ([_1]) is greater than the maximum quantity allowed ([_2])" =>
        "所要求之數量（[_1]）超出最大上限（[_2]）",

    "An error occurred while while creating or validating the current order" =>
        "在建立、或是確認目前訂單時，發生錯誤",

    "An error occurred during the checkout process" =>
        "在結帳程序中發生錯誤",

    ## param 1 violations
    "Param 1 is not a HASH reference" =>
        "第一個參數不是雜湊參照",

    "Cart reference is not a HASH reference or Handel::Cart" =>
        "購物車之參照應為雜湊參照或為 Handel::Cart 物件",

    "Param 1 is not a HASH reference or Handel::Cart::Item" =>
        "第一個參數應為雜湊參照或為 Handel::Cart::Item 物件",

    "Param 1 is not a HASH reference, Handel::Order::Item or Handel::Cart::Item" =>
        "第一個參數應為雜湊參照、Handel::Order::Item 物件、或為 Handel::Cart::Item 物件",

    "Unknown restore mode" =>
        "不明的修復模式",

    "Currency code '[_1]' is invalid or malformed" =>
        "貨幣代碼 '[_1]' 無效或格式錯誤",

    "Param 1 is not a a valid CHECKOUT_PHASE_* value" =>
        "第一個參數應為正確有效的 CHECKOUT_PHASE_* 值",

    "Param 1 is not a CODE reference" =>
        "第一個參數應為源碼參照",

    "Param 1 is not an ARRAY reference" =>
        "第一個參數應為陣列參照",

    "Param 1 is not an ARRAY reference or string" =>
        "第一個參數應為陣列參照或字串",

    "Param 1 is not a HASH reference, Handel::Order object, or order id" =>
        "第一個參數應為雜湊參照、Handel::Object 物件、或一訂單代碼",

    "Param 1 is not a Handel::Checkout::Message object or text message" =>
        "第一個參數與為 Handel::Checkout::Message 物件、或文字訊息",

    ## Taglib exceptions
    "Tag '[_1]' not valid inside of other Handel tags" =>
        "在 Handel 標籤之中，'[_1]' 此標籤是無效的",

    "Tag '[_1]' not valid here" =>
        "此處不可用 '[_1]' 此標籤",

    ## naughty bits
    "has invalid value" =>
        "其值無效",

    "[_1] value already exists" =>
        "[_1] 此值已存在",

    ## Order exceptions
    "Could not find a cart matching the supplid search criteria" =>
        "利用所給定的搜尋條件，無法找到相符的購物車",

    "Could not create a new order because the supplied cart is empty" =>
        "因給定的購物車內無項目，無法建立新訂單",

    ## Checkout exception
    "No order is assocated with this checkout process" =>
        "此結帳程序未與任何訂單關聯",
);

1;
__END__

=head1 NAME

Handel::L10N::zh_tw - Handel Language Pack: Traditional Chinese

=head1 AUTHOR

    Kang-min Liu
    CPAN ID: GUGOD
    gugod@gugod.org
    http://gugod.org
    http://gugod.blogspot.com

