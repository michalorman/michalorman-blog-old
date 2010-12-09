package demo.springdm;

import demo.springdm.api.AuthorizationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;

/**
 * @author Michal Orman
 * @version 1.0
 */
@Component
public class AuthorizationClient {

    @Autowired
    private AuthorizationService authorizationService;

    @PostConstruct
    public void authorize() {
        System.out.println("Authorization for foo:bar : " + authorizationService.authorize("foo", "bar"));
        System.out.println("Authorization for foo:secret : " + authorizationService.authorize("foo", "secret"));
    }
}
