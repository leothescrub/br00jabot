import StringIO
import json
import logging
import random
import urllib
import urllib2

# for sending images
from PIL import Image
import multipart

# standard app engine imports
from google.appengine.api import urlfetch
from google.appengine.ext import ndb
import webapp2

TOKEN = '<api_key>'

BASE_URL = 'https://api.telegram.org/bot' + TOKEN + '/'

VERSION = '0.420'
# ================================

class EnableStatus(ndb.Model):
    # key name: str(chat_id)
    enabled = ndb.BooleanProperty(indexed=False, default=False)


# ================================

def setEnabled(chat_id, yes):
    es = EnableStatus.get_or_insert(str(chat_id))
    es.enabled = yes
    es.put()

def getEnabled(chat_id):
    es = EnableStatus.get_by_id(str(chat_id))
    if es:
        return es.enabled
    return False


# ================================

class MeHandler(webapp2.RequestHandler):
    def get(self):
        urlfetch.set_default_fetch_deadline(60)
        self.response.write(json.dumps(json.load(urllib2.urlopen(BASE_URL + 'getMe'))))


class GetUpdatesHandler(webapp2.RequestHandler):
    def get(self):
        urlfetch.set_default_fetch_deadline(60)
        self.response.write(json.dumps(json.load(urllib2.urlopen(BASE_URL + 'getUpdates'))))


class SetWebhookHandler(webapp2.RequestHandler):
    def get(self):
        urlfetch.set_default_fetch_deadline(60)
        url = self.request.get('url')
        if url:
            self.response.write(json.dumps(json.load(urllib2.urlopen(BASE_URL + 'setWebhook', urllib.urlencode({'url': url})))))


class WebhookHandler(webapp2.RequestHandler):
    def post(self):
        urlfetch.set_default_fetch_deadline(60)
        body = json.loads(self.request.body)
        logging.info('request body:')
        logging.info(body)
        self.response.write(json.dumps(body))

        update_id = body['update_id']
        message = body['message']
        message_id = message.get('message_id')
        date = message.get('date')
        text = message.get('text')
        fr = message.get('from')
        chat = message['chat']
        chat_id = chat['id']

        if not text:
            logging.info('no text')
            return

        def reply(msg=None, img=None):
            if msg:
                resp = urllib2.urlopen(BASE_URL + 'sendMessage', urllib.urlencode({
                    'chat_id': str(chat_id),
                    'text': msg.encode('utf-8'),
                    'disable_web_page_preview': 'true',
                    'reply_to_message_id': str(message_id),
                })).read()
            elif img:
                resp = multipart.post_multipart(BASE_URL + 'sendPhoto', [
                    ('chat_id', str(chat_id)),
                    ('reply_to_message_id', str(message_id)),
                ], [
                    ('photo', 'image.jpg', img),
                ])
            else:
                logging.error('no msg or img specified')
                resp = None

            logging.info('send response:')
            logging.info(resp)

        if text.startswith('/'):
            if text == '/start':
                reply('Bienvenido a la experiencia memetica 2.0, quizas debas utilizar /help para conocer mas sobre los comandos.')
                setEnabled(chat_id, True)
            elif text == '/stop':
                reply('Oww :(')
                setEnabled(chat_id, False)
            elif text == '/image':
                img = Image.new('RGB', (512, 512))
                base = random.randint(0, 16777216)
                pixels = [base+i*j for i in range(512) for j in range(512)]  # generate sample image
                img.putdata(pixels)
                output = StringIO.StringIO()
                img.save(output, 'JPEG')
                reply(img=output.getvalue())
            elif text == '/quelacreo':
                reply('La version de este bot es ', VERSION) #Revisar, no esta mostrando la version
            elif text == '/help':
                reply ('Buena nueva! Movi el culo y coloque cosas en este comando \n1-/quelacreo Muestra la version del bot\n2-/stop Detiene las funciones del bot\n\nY... Eso es todo.')
            elif text == '/mememaster':
                reply('PASTA INCOMING')
                reply('ah pues maldito maricon, debes saber que yo fui al gym maldito comemierda y me la pasaba echandole maltas a los culos de las carajas que estaban ahi mientras me las pegaba y levantaba pesas, tambien se lo mamaba a los otros carajos que estaban ahi que se ponian todos maricos a decirme "ay papi tu si tas bueno" yo les decia "ay vale, maldito maricon de mierda, tu lo que quieres es que te mame el guevo verdad, muchacho marico pelate esa vaina" y se la pelaba y yo le daba, asi que no creas que me voy a cortar contigo maldito marico, que te tengo fichado bruja, becerro, cdtm sapo diablon, MAMAGUEVO, debes saber que de carajito me quedaba con mi mama a amarrar hallacas en la casa asi que se todo sobre defenderme muchacho marico, asi que abre canchas pues, tu crees que me arde el culo? no papa, yo soy experto en aguantar ardor de culo, ya que me meto los dildos de mi mama para estimular mi prostata, tambien lo hago en el gym y las tipas les gusta, asi que habla claro becerro.  Tu quieres que yo te lo mame o que?')
            else:
                reply('Belga chamo, no tengo ese comando')

        # CUSTOMIZE FROM HERE

        elif 'Chavez vive' in text:
            reply('LA LUCHA SIGUE!!!!')
        elif 'what time' in text:
            reply('look at the top-right corner of your screen!')
        else:
            if getEnabled(chat_id):
                try:
                    resp1 = json.load(urllib2.urlopen('http://www.simsimi.com/requestChat?lc=en&ft=1.0&req=' + urllib.quote_plus(text.encode('utf-8'))))
                    back = resp1.get('res').get('msg')
                except urllib2.HTTPError, err:
                    logging.error(err)
                    back = str(err)
                if not back:
                    reply('okay...')
                elif 'I HAVE NO RESPONSE' in back:
                    reply('El bot no entiende que carajo estas diciendo broder')
                else:
                    reply(back)
            else:
                logging.info('not enabled for chat_id {}'.format(chat_id))

app = webapp2.WSGIApplication([
    ('/me', MeHandler),
    ('/updates', GetUpdatesHandler),
    ('/set_webhook', SetWebhookHandler),
    ('/webhook', WebhookHandler),
], debug=True)
