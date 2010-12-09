package demo.springdm.api;

/**
 * @author Michal Orman
 * @version 1.0
 */
public interface AuthorizationService {

    boolean authorize(String username, String password);

}
