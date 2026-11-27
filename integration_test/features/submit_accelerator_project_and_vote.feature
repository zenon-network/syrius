@chain
Feature: Submit Accelerator-Z project and vote

  Scenario Outline: Submitting an Accelerator-Z project and casting Pillar votes through the UI
    Given <owner_address> is prepared for submitting an Accelerator-Z project
    When <owner_address> submits Accelerator-Z project <name>, <description>, <url>, <znn_funds>, and <qsr_funds> from the Create Project stepper
    Then the blockchain should contain the submitted Accelerator-Z project with <name>, <description>, <url>, <znn_funds>, and <qsr_funds>
    When Pillar producer <producer_address> votes yes and Pillar owner <pillar_owner_address> votes no on the submitted Accelerator-Z project
    Then the blockchain should record the yes vote from <producer_pillar> and no vote from <owner_pillar> on the submitted Accelerator-Z project

    Examples:
      | owner_address                              | name             | description                            | url                     | znn_funds | qsr_funds | producer_address                           | producer_pillar | pillar_owner_address                       | owner_pillar |
      | 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth' | 'Devnet Accel Z' | 'Verify Accelerator-Z create and vote' | 'https://zenon.network' | '10'      | '100'     | 'z1qq9n7fpaqd8lpcljandzmx4xtku9w4ftwyg0mq' | 'dev1'          | 'z1qqleq9qc2u3039fly4ld5qgngdeapa3yks0e3l' | 'dev2'       |
