package demo.springdm.api.impl;

import demo.springdm.api.AuthorizationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author Michal Orman
 * @version 1.0
 */
public class DefaultAuthorizationService implements AuthorizationService {
    private static final Logger logger = LoggerFactory.getLogger(DefaultAuthorizationService.class);

    public boolean authorize(String username, String password) {
        logger.info("Attepting to authrozie username: '{}', password: '{}'", username, password);
        return "foo".equals(username) && "secret".equals(password);
    }
}
