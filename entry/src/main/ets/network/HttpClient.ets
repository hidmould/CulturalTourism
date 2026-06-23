import { http } from '@kit.NetworkKit'
import { ApiConfig } from './ApiConfig'

/**
 * HTTP 客户端封装
 * 支持普通请求和流式请求
 */
export class HttpClient {
  private static instance: HttpClient

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient()
    }
    return HttpClient.instance
  }

  /**
   * 发送POST JSON请求
   */
  async postJson(url: string, body: string, authKey: string): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': authKey
        },
        extraData: body,
        connectTimeout: ApiConfig.HTTP_TIMEOUT,
        readTimeout: ApiConfig.HTTP_TIMEOUT
      }

      const response = await httpRequest.request(url, requestOptions)

      if (response.responseCode === 200) {
        return response.result as string
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`)
      }
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 发送GET请求
   */
  async get(url: string): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: ApiConfig.HTTP_TIMEOUT,
        readTimeout: ApiConfig.HTTP_TIMEOUT
      }

      const response = await httpRequest.request(url, requestOptions)

      if (response.responseCode === 200) {
        return response.result as string
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`)
      }
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 发送流式POST请求（SSE）
   * 返回响应字符串，由调用方自行解析SSE格式
   */
  async postStream(url: string, body: string, authKey: string): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          'Authorization': authKey
        },
        extraData: body,
        connectTimeout: ApiConfig.HTTP_TIMEOUT,
        readTimeout: ApiConfig.SSE_TIMEOUT
      }

      const response = await httpRequest.request(url, requestOptions)

      if (response.responseCode === 200) {
        return response.result as string
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`)
      }
    } finally {
      httpRequest.destroy()
    }
  }
}