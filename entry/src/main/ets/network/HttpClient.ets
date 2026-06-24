/**
 * HTTP 网络请求客户端
 */
import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

export interface StreamRequest {
  request: http.HttpRequest
  options: http.HttpRequestOptions
}

export class HttpClient {
  private static instance: HttpClient

  private static getDefaultHeaders(): Object {
    let headers: Record<string, string> = {}
    headers['Content-Type'] = 'application/json'
    return headers
  }

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient()
    }
    return HttpClient.instance
  }

  /**
   * GET 请求
   */
  async get(url: string, headers?: Record<string, string>): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      let reqHeaders: Object
      if (headers !== undefined) {
        reqHeaders = headers
      } else {
        reqHeaders = HttpClient.getDefaultHeaders()
      }
      let options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: reqHeaders,
        connectTimeout: 30000,
        readTimeout: 30000
      }
      let response = await httpRequest.request(url, options)
      if (response.responseCode === 200) {
        return response.result as string
      }
      throw new Error(`HTTP ${response.responseCode}: ${response.result}`)
    } catch (err) {
      let error = err as BusinessError
      throw new Error(`网络请求失败: ${error.message}`)
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * POST 请求（JSON）
   */
  async post(url: string, body: string, headers?: Record<string, string>): Promise<string> {
    const httpRequest = http.createHttp()
    try {
      let reqHeaders: Object
      if (headers !== undefined) {
        reqHeaders = headers
      } else {
        reqHeaders = HttpClient.getDefaultHeaders()
      }
      let options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: reqHeaders,
        extraData: body,
        connectTimeout: 60000,
        readTimeout: 120000
      }
      let response = await httpRequest.request(url, options)
      if (response.responseCode === 200) {
        return response.result as string
      }
      throw new Error(`HTTP ${response.responseCode}: ${response.result}`)
    } catch (err) {
      let error = err as BusinessError
      throw new Error(`网络请求失败: ${error.message}`)
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 创建流式 POST 请求对象（用于 SSE / 大模型流式输出）
   * 返回 httpRequest 对象和请求选项，由调用方监听事件并执行 requestInStream
   */
  createStreamRequest(headers?: Record<string, string>): StreamRequest {
    const httpRequest = http.createHttp()
    let defaultHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache'
    }
    if (headers) {
      Object.keys(headers).forEach(key => {
        defaultHeaders[key] = headers[key]
      })
    }
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: defaultHeaders,
      connectTimeout: 60000,
      readTimeout: 120000
    }
    let result: StreamRequest = {
      request: httpRequest,
      options: options
    }
    return result
  }
}