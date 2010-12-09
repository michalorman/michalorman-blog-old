package demo.springdm.api.impl;

import demo.springdm.api.AuthorizationService;

/**
 * @author Michal Orman
 * @version 1.0
 */
public class DefaultAuthorizationService implements AuthorizationService {
    public boolean authorize(String username, String password) {
        return "foo".equals(username) && "secret".equals(password);
    }
}
