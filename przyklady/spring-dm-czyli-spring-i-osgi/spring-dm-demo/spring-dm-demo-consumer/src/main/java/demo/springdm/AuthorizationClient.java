package demo.springdm;

import demo.springdm.api.AuthorizationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;

/**
 * @author Michal Orman
 * @version 1.0
 */
@Component
public class AuthorizationClient {
    private static final Logger logger = LoggerFactory.getLogger(AuthorizationClient.class);

    @Autowired
    private AuthorizationService authorizationService;

    @PostConstruct
    public void authorize() {
        logger.info("authorization result: '{}'", authorizationService.authorize("foo", "bar"));
        logger.info("authorization result: '{}'", authorizationService.authorize("foo", "secret"));
    }
}
