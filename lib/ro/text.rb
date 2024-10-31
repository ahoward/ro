module Ro
  require 'cgi'

  module Text
    def render(text)
      text = text.to_s.strip
      return '' if text.empty?

      text = escape_html(text)
      text = auto_link_urls(text)
      text = auto_link_email_addresses(text)
      text = paragraphs_for(text)

      return text
    end

    def paragraphs_for(text)
      paragraphs = text.split(%r`\n\n+`).map{|chunk| lines_for(chunk)}
      paragraphs.map{|p| "<p>\n#{ p }\n</p>"}.join("\n\n").strip
    end

    def lines_for(text)
      text.strip.gsub(/\n/, "<br />\n")
    end

    def escape_html(text)
      CGI.escapeHTML(text)
    end

    AUTO_LINK_RE = %r{
        (?: ((?:ed2k|ftp|http|https|irc|mailto|news|gopher|nntp|telnet|webcal|xmpp|callto|feed|svn|urn|aim|rsync|tag|ssh|sftp|rtsp|afs|file):)// | www\.\w )
        [^\s<\u00A0"]+
      }ix

    # regexps for determining context, used high-volume
    AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]

    AUTO_EMAIL_LOCAL_RE = /[\w.!#\$%&'*\/=?^`{|}~+-]/
    AUTO_EMAIL_RE = /(?<!#{AUTO_EMAIL_LOCAL_RE})[\w.!#\$%+-]\.?#{AUTO_EMAIL_LOCAL_RE}*@[\w-]+(?:\.[\w-]+)+/

    BRACKETS = { ']' => '[', ')' => '(', '}' => '{' }

    WORD_PATTERN = '\p{Word}'

    # Turns all urls into clickable links.  If a block is given, each url
    # is yielded and the result is used as the link text.
    def auto_link_urls(text)
      text.gsub(AUTO_LINK_RE) do
        scheme, href = $1, $&
        punctuation = []
        trailing_gt = ""

        if auto_linked?($`, $')
          # do not change string; URL is already linked
          href
        else
          # don't include trailing punctuation character as part of the URL
          while href.sub!(/[^#{WORD_PATTERN}\/\-=;]$/, '')
            punctuation.push $&
            if opening = BRACKETS[punctuation.last] and href.scan(opening).size > href.scan(punctuation.last).size
              href << punctuation.pop
              break
            end
          end

          # don't include trailing &gt; entities as part of the URL
          trailing_gt = $& if href.sub!(/&gt;$/, '')
          href = 'http://' + href unless scheme
          link = escape_html(href)
          "<a href='#{ link }'>#{ link }</a>" + punctuation.reverse.join('') + trailing_gt
        end
      end
    end

    # Turns all email addresses into clickable links.  If a block is given,
    # each email is yielded and the result is used as the link text.
    def auto_link_email_addresses(text)
      text.gsub(AUTO_EMAIL_RE) do
        text = $&

        if auto_linked?($`, $')
          text
        else
          email = escape_html(text)
          "<a href='mailto:#{ email }'>#{ email }</a>"
        end
      end
    end

    # Detects already linked context or position in the middle of a tag
    def auto_linked?(left, right)
      (left =~ AUTO_LINK_CRE[0] and right =~ AUTO_LINK_CRE[1]) or
        (left.rindex(AUTO_LINK_CRE[2]) and $' !~ AUTO_LINK_CRE[3])
    end

    extend self
  end
end




END {
  text = <<~____
    this is a paragraph that is very long this is a paragraph that is very long this is a paragraph that is very long this is a paragraph that is very long
    this is a paragraph that is very long this is a paragraph that is very long this is a paragraph that is very long this is a paragraph that is very long

    this is a paragraph that is very long this is a paragraph that is very long this is a paragraph that is very long this is a paragraph that is very long

    - a
    - b
    - c

    & < > me

    http://drawohara.io>

    ara.t.howard@gmail.com
  ____

  puts Text.render(text)
}
