package daemon

import (
	"net/http"
	"crypto/tls"
	"time"

	"github.com/drone/runner-go/client"
)

func newRunnerClient(endpoint, secret string, skipverify bool, timeout int) *client.HTTPClient {
	httpClient := http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Timeout: time.Second * time.Duration(timeout),
	}
    if skipverify {
		httpClient.Transport = &http.Transport{
			Proxy: http.ProxyFromEnvironment,
			TLSClientConfig: &tls.Config{
				InsecureSkipVerify: true,
			},
		}
    }
    client := &client.HTTPClient{
        Endpoint:   endpoint,
        Secret:     secret,
        SkipVerify: skipverify,
		Client:     &httpClient,
    }
    return client
}

